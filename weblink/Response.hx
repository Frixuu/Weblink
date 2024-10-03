package weblink;

import haxe.http.HttpStatus;
import haxe.io.Bytes;
import haxe.io.Encoding;
import weblink.Cookie;
import weblink._internal.HttpStatusMessage;
import weblink.http.HeaderMap;
import weblink.tcp.ITcpClient;

private typedef Write = (bytes:Bytes) -> Bytes;

class Response {
	public var status:HttpStatus;
	public var contentType(get, set):String;
	public final headers:HeaderMap;
	public var cookies:List<Cookie> = new List<Cookie>();
	public var write:Null<Write>;

	private var client:Null<ITcpClient>;
	var close:Bool = false; // default in HTTP/1.1

	private function new(client:ITcpClient) {
		this.client = client;
		this.headers = new HeaderMap();
		contentType = "text/html";
		status = OK;
	}

	public inline function set_contentType(value:String):String {
		this.headers.set(ContentType, value);
		return value;
	}

	public inline function get_contentType():String {
		return this.headers.get(ContentType);
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
			client.writeBytes(Bytes.ofString(collectHeaders(bytes.length).toString()));
			client.writeBytes(bytes);
		} catch (_) {
			// The connection has already been closed, silently ignore
		}

		this.end();
	}

	public inline function redirect(path:String) {
		status = MovedPermanently;
		var string = initLine();
		string += 'Location: $path\r\n\r\n';
		this.client.writeBytes(Bytes.ofString(string));
		end();
	}

	public inline function send(data:String) {
		this.sendBytes(Bytes.ofString(data, Encoding.UTF8));
	}

	private function end() {
		final client = this.client;
		if (client != null) {
			if (this.close) {
				client.closeAsync();
			}
			this.client = null;
		}
	}

	private inline function initLine():String {
		return 'HTTP/1.1 $status ${HttpStatusMessage.fromCode(status)}\r\n';
	}

	public inline function collectHeaders(length:Int):StringBuf {
		var string = new StringBuf();
		string.add(this.initLine());

		this.headers.add(Connection, close ? (cast "close") : (cast "keep-alive"));
		this.headers.set(ContentLength, Std.string(length));

		for (cookie in cookies) {
			this.headers.add(SetCookie, cookie.resolveToResponseString());
		}

		for (headerName => values in this.headers) {
			if (values.length <= 0) // Sanity check
				continue;

			if (headerName == SetCookie) {
				for (headerValue in values) {
					string.add(headerName);
					string.add(": ");
					string.add(headerValue);
					string.add("\r\n");
				}
			} else {
				string.add(headerName);
				string.add(": ");
				if (values.length == 1) {
					string.add(values[0]);
				} else if (headerName.allowsRawCommaSeparatedValues()) {
					string.add(values.join(", "));
				} else if (headerName.allowsRawSemicolonSeparatedValues()) {
					string.add(values.join("; "));
				} else if (headerName.doesNotAllowRepeats()) {
					throw 'unique header "$headerName" has ${values.length} assigned values';
				} else {
					string.add(Lambda.map(values, v -> '"$v"').join(", "));
				}
				string.add("\r\n");
			}
		}

		this.headers.clear();
		string.add("\r\n");
		return string;
	}
}
