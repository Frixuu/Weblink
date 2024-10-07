package weblink._internal.hashlink;

#if hl
import haxe.EntryPoint;
import haxe.Exception;
import haxe.Timer;
import hl.Gc;
import hl.uv.Loop;
import sys.net.Host;
import sys.net.Socket;
import sys.thread.EventLoop;
import sys.thread.Lock;
import sys.thread.Thread;
import weblink.tcp.ITcpClient;
import weblink.tcp.ITcpServer;

using Lambda;

/**
	TCP server implementation for Hashlink virtual machine,
	dependent on provided libuv bindings.
**/
@:nullSafety(StrictThreaded)
final class HashlinkTcpServer implements ITcpServer {

	private final closeLock:Lock;
	private var innerServer:Null<UvTcpHandle>;
	private var serverThread:Null<Thread>;
	private var helperTimer:Null<Timer>;
	private var uvLoop:Loop;

	public var isRunning(get, never):Bool;

	private inline function get_isRunning():Bool {
		return this.serverThread != null;
	}

	public function new() {
		this.closeLock = new Lock();
		this.innerServer = null;
		this.uvLoop = @:privateAccess Loop.default_loop(); // prevent MainLoop event registration
		if (this.uvLoop == null) {
			throw new UvException("Could not get/allocate default libuv loop");
		}
	}

	public function startAsync(
		host:Host,
		port:Int,
		configureClient:(client:ITcpClient) -> Void,
		?callback:() -> Void
	) {

		// Create and bind libuv TCP socket
		final server = this.innerServer = UvTcpHandle.initWrapOrThrow(this.uvLoop);
		server.noDelay = true;
		server.bindOrThrow(host, port);

		// Configure new connection callback
		server.listenOrThrow(100, () -> {

			Gc.enable(true);

			final client = new HashlinkTcpClient(this, server.acceptOrThrow());
			configureClient(client);
			client.startReading();

			// Hashlink libuv bindings only allow for filesystem and TCP connection events.
			// We use the fact that a new connection is opened to trigger Haxe's event loop.
			// We have to run it on the same thread
			// in case some of the events call (non-thread safe) libuv APIs.
			final currentThread = Thread.current();
			final events = currentThread.events;
			if (events != null) {
				final _ = events.progress();
			}

			Gc.enable(false);
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

			if (callback != null) {
				@:nullSafety(Off) callback();
			}

			Gc.enable(false);

			try {
				this.uvLoop.run(Default);
			} catch (e:Exception) {
				trace(e.details());
			}

			Gc.enable(true);
			this.closeLock.release();
		});

		// Create thread #2 which will periodically wake up thread #1 with TCP connections,
		// so that the event loop is run even when the server gets no traffic.
		if (port != 0) {

			// Of course, this trick only works if we know the port:
			// unfortunately, we cannot get it from a running server
			Thread.createWithEventLoop(() -> {

				#if (haxe_ver >= 4.3) Thread.current().setName("Timer sch. hack"); #end
				final host = new Host("127.0.0.1");
				final timer = this.helperTimer = new Timer(500);
				timer.run = () -> {
					final socket = new Socket();
					final _ = @:privateAccess Socket.socket_connect(socket.__s, host.ip, port);
					socket.close(); // Immediately close not to eat up too much resources
				};
			});
		}

		// Prevent the process from exiting
		final mainThread = @:privateAccess EntryPoint.mainThread;
		mainThread.events.promise();
	}

	public function closeAsync(?callback:() -> Void):Bool {

		// The server can be requested to close only once
		final innerServer = this.innerServer;
		this.innerServer = null;
		if (innerServer == null) {
			return false;
		}

		final serverThread = this.serverThread;
		this.serverThread = null;
		if (serverThread != null) {
			serverThread.events.run(() -> {
				@:nullSafety(Off) innerServer.closeAsync(() -> {

					this.uvLoop.stop();

					final helperTimer = this.helperTimer;
					this.helperTimer = null;
					if (helperTimer != null) {
						helperTimer.stop();
					}

					if (callback != null) {
						@:nullSafety(Off) callback();
					}
				});
			});
		}

		// Allow the app to exit
		final mainThread = @:privateAccess EntryPoint.mainThread;
		mainThread.events.runPromised(() -> {});
		return true;
	}
}
#end
