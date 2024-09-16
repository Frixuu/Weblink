package weblink;

import haxe.http.HttpStatus;
import haxe.io.Bytes;
import haxe.io.Encoding;
import haxe.io.Eof;
import weblink.Cookie;
import weblink._internal.HttpStatusMessage;
import weblink._internal.TcpServer;
import weblink._internal.WebServer;

private typedef Write = (bytes:Bytes) -> Bytes;

class Response {
	public var status:HttpStatus;
	public var contentType:String;
	public var headers:Null<List<Header>>;
	public var cookies:List<Cookie> = new List<Cookie>();
	public var write:Null<Write>;

	var client:Null<ClientHandle>;
	var server:Null<WebServer>;
	var close:Bool = true;

	private function new(client:ClientHandle, server:WebServer) {
		this.client = client;
		this.server = server;
		contentType = "text/html";
		status = OK;
	}

	public function sendBytes(bytes:Bytes) {
		final client = this.client;
		if (client == null) {
			throw "trying to push more data to a Response that has already been completed";
		}

		final transformer = this.write;
		if (transformer != null) {
			bytes = transformer(bytes);
		}

		try {
			client.writeString(sendHeaders(bytes.length).toString());
			client.writeBytes(bytes);
		} catch (_:Eof) {
			// The connection has already been closed, silently ignore
		}

		end();
	}

	public inline function redirect(path:String) {
		status = MovedPermanently;
		headers = new List<Header>();
		var string = initLine();
		string += 'Location: $path\r\n\r\n';
		this.client.writeString(string);
		end();
	}

	public inline function send(data:String) {
		this.sendBytes(Bytes.ofString(data, Encoding.UTF8));
	}

	private function end() {
		this.server = null;
		var client = this.client;
		if (client != null) {
			if (this.close) {
				client.close();
			}
			this.client = null;
		}
	}

	private inline function initLine():String {
		return 'HTTP/1.1 $status ${HttpStatusMessage.fromCode(status)}\r\n';
	}

	public inline function sendHeaders(length:Int):StringBuf {
		var string = new StringBuf();
		string.add(initLine()
			+ // 'Acess-Control-Allow-Origin: *\r\n' +
			'Connection: ${close ? "close" : "keep-alive"}\r\n'
			+ 'Content-type: $contentType\r\n'
			+ 'Content-length: $length\r\n');
		for (cookie in cookies) {
			string.add("Set-Cookie: " + cookie.resolveToResponseString() + "\r\n");
		}
		if (headers != null) {
			for (header in headers) {
				string.add(header.key + ": " + header.value + "\r\n");
			}
			headers = null;
		}
		string.add("\r\n");
		return string;
	}
}
