package weblink._internal.nodejs;

#if js
import haxe.io.Bytes;
import js.node.Buffer;
import js.node.Net;
import js.node.net.Server;
import js.node.net.Socket;
import sys.net.Host;
import weblink._internal.TcpServer;

final class NodeTcpServer extends TcpServer {
	private var nodeServer:Server;

	public function new() {
		this.nodeServer = Net.createServer(cast {noDelay: true}, null);
	}

	public function listen(host:Host, port:Int, callback:(client:TcpServer.ClientHandle) -> Void) {
		this.nodeServer.on(Connection, socket -> {
			final handle = new ClientHandle(socket);
			callback(handle);
		});
		this.nodeServer.listen(port, host.host, 100, null);
	}

	public override function close(?callback:() -> Void) {
		this.nodeServer.close(callback);
		@:nullSafety(Off) this.nodeServer = null;
	}
}

final class ClientHandle extends TcpServer.ClientHandle {
	private var socket:Socket;

	public inline function new(socket:Socket) {
		this.socket = socket;
	}

	public function startReading(callback:(data:Null<Bytes>) -> Void):Void {
		this.socket.on(Data, data -> {
			final buffer:Buffer = data;
			callback(buffer.hxToBytes());
		});
		this.socket.on(Error, error -> {
			callback(null);
		});
	}

	public function writeBytes(bytes:Bytes) {
		this.socket.write(Buffer.hxFromBytes(bytes));
	}

	public function close(?callback:() -> Void) {
		this.socket.end(callback);
		@:nullSafety(Off) this.socket = null;
	}
}
#end
