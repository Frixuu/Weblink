package weblink._internal;

import haxe.io.Bytes;
import sys.net.Host;

abstract class TcpServer {
	public abstract function listen(host:Host, port:Int, callback:(client:ClientHandle) -> Void):Void;

	public function poll():Bool {
		return false;
	}

	/** Closes the server and frees the underlying resources. **/
	public function close(?callback:() -> Void) {}

	/** Creates a new server instance that can be run on the current target. **/
	public static function create():TcpServer {
		#if (hl && !nolibuv)
		return new weblink._internal.hashlink.HashlinkTcpServer();
		#elseif (js && hxnodejs)
		return new weblink._internal.nodejs.NodeTcpServer();
		#else
		#error "Weblink does not support your target platform yet!"
		#end
	}
}

abstract class ClientHandle {
	public abstract function startReading(callback:(data:Null<Bytes>) -> Void):Void;

	public abstract function writeBytes(bytes:Bytes):Void;

	public function writeString(string:String):Void {
		this.writeBytes(Bytes.ofString(string, UTF8));
	}

	public abstract function close(?callback:() -> Void):Void;
}
