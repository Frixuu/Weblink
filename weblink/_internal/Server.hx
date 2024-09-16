package weblink._internal;

import haxe.MainLoop;
import hl.uv.Loop;
import sys.net.Host;
import weblink._internal.hashlink.UvStreamHandle;
import weblink._internal.hashlink.UvTcpHandle;

class Server {
	private var app:Weblink;
	private var uvLoop:Loop;
	private var tcpServer:UvTcpHandle;

	public var running:Bool = true;

	public function new(app:Weblink, host:String, port:Int) {
		this.app = app;
		this.uvLoop = Loop.getDefault() ?? throw "cannot get default loop";
		this.tcpServer = new UvTcpHandle(this.uvLoop);
		this.tcpServer.bind(new Host(host), port);
		this.tcpServer.setNodelay(true);
		this.tcpServer.listen(100, this.handleIncomingConnection);
	}

	private function handleIncomingConnection():Void {
		var client = this.tcpServer.accept() ?? return;
		var request:Null<Request> = null;
		var done:Bool = false;

		client.readStart(data -> @:privateAccess {
			if (done || data == null) {
				client.close();
				return;
			}

			if (request == null) {
				final lines = data.toString().split("\r\n");
				request = new Request(lines);

				if (request.pos >= request.length) {
					done = true;
					this.completeRequest(request, client);
					return;
				}
			} else if (!done) {
				final length = request.length - request.pos < data.length ? request.length - request.pos : data.length;
				request.data.blit(request.pos, data, 0, length);
				request.pos += length;

				if (request.pos >= request.length) {
					done = true;
					this.completeRequest(request, client);
					return;
				}
			}

			if (request.chunked) {
				request.chunk(data.toString());
				if (request.chunkSize == 0) {
					done = true;
					this.completeRequest(request, client);
					return;
				}
			}

			if (request.method != Post && request.method != Put) {
				done = true;
				this.completeRequest(request, client);
			}
		});
	}

	private function completeRequest(request:Request, clientStream:UvStreamHandle) {
		@:privateAccess var response = request.response(this, clientStream);

		if (request.method == Get
			&& @:privateAccess this.app._serve
			&& response.status == OK
			&& request.path.indexOf(@:privateAccess this.app._path) == 0) {
			if (@:privateAccess this.app._serveEvent(request, response)) {
				return;
			}
		}

		switch (this.app.routeTree.tryGet(request.basePath, request.method)) {
			case Found(handler, params):
				request.routeParams = params;
				handler(request, response);
			case _:
				switch (this.app.routeTree.tryGet(request.path, request.method)) {
					case Found(handler, params):
						request.routeParams = params;
						handler(request, response);
					case _:
						@:privateAccess this.app.pathNotFound(request, response);
				}
		}
	}

	public function update(blocking:Bool = true) {
		do {
			@:privateAccess MainLoop.tick(); // for timers
			this.uvLoop.run(NoWait);
		} while (this.running && blocking);
	}

	public function close(?callback:() -> Void) {
		this.tcpServer.close(callback);
		this.uvLoop.stop();
		this.running = false;
	}
}
