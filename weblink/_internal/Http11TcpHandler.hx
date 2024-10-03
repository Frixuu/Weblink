package weblink._internal;

import haxe.io.Bytes;
import weblink.tcp.ITcpClient;
import weblink.tcp.ITcpHandler;

/**
	A TCP handler that answers to HTTP/1.1 requests.
**/
@:nullSafety(StrictThreaded)
final class Http11TcpHandler implements ITcpHandler {
	private final app:Weblink;
	private var client:Null<ITcpClient>;
	private var currentRequest:Null<Request>;

	public function new(app:Weblink, client:ITcpClient) {
		this.app = app;
		this.client = client;
		this.currentRequest = null;
	}

	public function onData(data:Bytes) {

		final client = this.client;
		if (client == null) {
			throw "cannot consume data if the client allegedly disconnected";
		}

		var request = this.currentRequest;
		if (request == null) @:privateAccess {
			final lines = data.toString().split("\r\n");
			request = this.currentRequest = new Request(lines);
		} else
			@:privateAccess {
			var length = request.length - request.pos < data.length ? request.length - request.pos : data.length;
			request.data.blit(request.pos, data, 0, length);
			request.pos += length;
		}

		if (@:privateAccess request.pos >= request.length) {
			this.complete(request, client);
			this.currentRequest = null;
			return;
		}

		if (request.chunked) @:privateAccess {
			request.chunk(data.toString());
			if (request.chunkSize == 0) {
				this.complete(request, client);
				this.currentRequest = null;
				return;
			}
		}

		if (request.method != Post && request.method != Put) {
			this.complete(request, client);
			this.currentRequest = null;
		}
	}

	private function complete(request:Request, client:ITcpClient) {
		@:privateAccess var response = request.response(client);

		final app = this.app;
		if (request.method == Get
			&& @:privateAccess app._serve
			&& response.status == OK
			&& request.path.indexOf(@:privateAccess app._path) == 0) {
			if (@:privateAccess app._serveEvent(request, response)) {
				return;
			}
		}

		try {
			switch (app.routeTree.tryGet(request.basePath, request.method)) {
				case Found(handler, params):
					request.routeParams = params;
					handler(request, response);
				case _:
					switch (app.routeTree.tryGet(request.path, request.method)) {
						case Found(handler, params):
							request.routeParams = params;
							handler(request, response);
						case _:
							@:privateAccess app.pathNotFound(request, response);
					}
			}
		} catch (e) {
			trace(e.details());
			try {
				response.status = InternalServerError;
				response.send("Internal Server Error");
			} catch (_) {}
		}
	}

	public function onDisconnected() {
		this.currentRequest = null;
		this.client = null;
	}
}
