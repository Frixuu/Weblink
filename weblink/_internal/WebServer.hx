package weblink._internal;

import haxe.EntryPoint;
import haxe.Exception;
import haxe.Timer;
import hl.Gc;
import sys.net.Host;
import sys.thread.EventLoop;
import sys.thread.Lock;
import sys.thread.Thread;
import weblink._internal.libuv.UvLoop;
import weblink._internal.libuv.UvTcpHandle;

@:nullSafety(Off)
class WebServer {
	/**
		Is the server currently running?
	**/
	public var running:Bool;

	private final parent:Weblink;
	private final uvLoop:UvLoop;
	private var tcpSocket:Null<UvTcpHandle>;

	private var serverThread:Null<Thread>;
	private var helperTimer:Null<Timer>;

	public function new(app:Weblink) {
		this.uvLoop = UvLoop.defaultOrThrow();
		this.parent = app;
		this.running = false;
	}

	public function start(host:Host, port:Int, model:StartModel) {
		final lock = new Lock();

		// Prepare the libuv TCP socket
		final tcpSocket = this.tcpSocket = UvTcpHandle.initOrThrow(this.uvLoop);
		tcpSocket.noDelay = true;
		tcpSocket.bindOrThrow(host, port);

		// Configure new connection callback
		tcpSocket.listenOrThrow(100, function() {
			Gc.blocking(false);

			final client = tcpSocket.acceptOrThrow();

			// Register a handler for incoming data (HTTP/1.1 specific)
			var request:Null<Request> = null;
			client.readStartOrThrow(data -> @:privateAccess {
				Gc.blocking(false);

				switch (data) {
					case Error(_):
						request = null;
						client.closeAsync();
					case Data(bytes):
						if (request == null) {
							final lines = bytes.toString().split("\r\n");
							request = new Request(lines);
							if (request.pos >= request.length) {
								this.complete(request, client);
								request = null;
								Gc.blocking(true);
								return;
							}
						} else {
							final length = if (request.length - request.pos < bytes.length) {
								request.length - request.pos;
							} else {
								bytes.length;
							};
							request.data.blit(request.pos, bytes, 0, length);
							request.pos += length;
							if (request.pos >= request.length) {
								this.complete(request, client);
								request = null;
								Gc.blocking(true);
								return;
							}
						}

						if (request.chunked) {
							request.chunk(bytes.toString());
							if (request.chunkSize == 0) {
								this.complete(request, client);
								request = null;
								Gc.blocking(true);
								return;
							}
						}

						if (request.method != Post && request.method != Put) {
							this.complete(request, client);
							request = null;
						}
				}

				Gc.blocking(true);
			});

			// Hashlink libuv bindings only allow for filesystem and TCP connection events.
			// We use the fact that a new connection is opened to trigger Haxe's event loop.
			// We have to run it on the same thread
			// in case some of the events call (non-thread safe) libuv APIs.
			final currentThread = Thread.current();
			final events = currentThread.events;
			try {
				events.progress();
			} catch (e) {
				trace(e.details());
			}

			Gc.blocking(true);
		});

		// Create a thread to run the server's event loop
		final serverThread = this.serverThread = Thread.create(() -> {
			final currentThread = Thread.current();
			#if (haxe_ver >= 4.3) currentThread.setName("TCP listener"); #end

			// If we simply called Thread.createWithEventLoop up here,
			// the thread would not stop after this block,
			// but would continue running through the registered events.
			// This way, setting Haxe's loop manually,
			// our thread is guaranteed to eventually terminate.
			Reflect.setProperty(currentThread, "events", new EventLoop());

			this.running = true;
			if (model == BlockUntilReady) {
				lock.release();
			}

			Gc.blocking(true);
			this.uvLoop.run(Default);
			Gc.blocking(false);

			if (model == BlockUntilClosed) {
				lock.release();
			}
		});

		// Create thread #2 which will periodically wake up thread #1 with TCP connections.
		// When the server gets no traffic, this has two side effects:
		// 1) the Haxe event loop is still run,
		// 2) the GC can still collect garbage.
		if (port != 0) {
			// Of course, this trick only works if we know the port:
			// unfortunately, we cannot get it from a running server
			Thread.createWithEventLoop(() -> {
				#if (haxe_ver >= 4.3) Thread.current().setName("Timer sch. hack"); #end
				final host = new Host("127.0.0.1");
				final timer = this.helperTimer = new Timer(557);
				timer.run = () -> {
					final socket = new sys.net.Socket();
					final _ = @:privateAccess sys.net.Socket.socket_connect(socket.__s, host.ip, port);
					socket.close(); // Immediately close not to eat up too much resources
				};
			});
		}

		// Prevent the process from exiting
		final mainThread = @:privateAccess EntryPoint.mainThread;
		mainThread.events.promise();

		// Wait until the server is either ready or closed
		lock.wait();
	}

	private function complete(request:Request, socket:UvTcpHandle) {
		@:privateAccess var response = request.response(this, socket);

		if (request.method == Get
			&& @:privateAccess parent._serve
			&& response.status == OK
			&& request.path.indexOf(@:privateAccess parent._path) == 0) {
			if (@:privateAccess parent._serveEvent(request, response)) {
				return;
			}
		}

		switch (parent.routeTree.tryGet(request.basePath, request.method)) {
			case Found(handler, params):
				request.routeParams = params;
				handler(request, response);
			case _:
				switch (parent.routeTree.tryGet(request.path, request.method)) {
					case Found(handler, params):
						request.routeParams = params;
						handler(request, response);
					case _:
						@:privateAccess parent.pathNotFound(request, response);
				}
		}
	}

	@:deprecated("Updates are now done in the background. You can try to remove this call.")
	public function update(blocking:Bool = true) {
		// Pretend to block not to change the method's semantics
		final lock = new Lock();
		while (this.running && blocking) {
			lock.wait(0.1);
		}
	}

	/**
		Closes this server.
	**/
	public function closeSync() {
		final serverThread = this.serverThread;
		this.serverThread = null;
		if (serverThread != null) {
			final lock = new Lock();
			serverThread.events.run(() -> {
				final tcpSocket = this.tcpSocket;
				this.tcpSocket = null;
				if (tcpSocket != null) {
					tcpSocket.closeAsync(() -> {
						this.uvLoop.stop();
						this.running = false;

						final helperTimer = this.helperTimer;
						this.helperTimer = null;
						if (helperTimer != null) {
							helperTimer.stop();
						}

						lock.release();

						// Allow the app to exit
						final mainThread = @:privateAccess EntryPoint.mainThread;
						mainThread.events.runPromised(() -> {});
					});
				}
			});
			lock.wait(10.0);
		}
	}
}

private enum abstract StartModel(Bool) {
	/** The `start()` call will return when the server is ready to accept connections. **/
	public var BlockUntilReady = false;

	/** The `start()` call will return when the server is closed. **/
	public var BlockUntilClosed = true;
}
