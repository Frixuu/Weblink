package weblink._internal.nodejs;

#if js
import haxe.io.Bytes;
import js.node.Buffer;
import js.node.Net;
import js.node.net.Server;
import js.node.net.Socket;
import sys.NodeSync;
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
		var listening:Bool = false;
		this.nodeServer.listen(port, host.host, 100, () -> listening = true);
		NodeSync.wait(() -> listening);
	}

	public override function close(?callback:() -> Void) {
		final nodeServer = this.nodeServer;
		@:nullSafety(Off) this.nodeServer = null;
		var closed:Bool = false;
		nodeServer.close(() -> {
			if (callback != null)
				@:nullSafety(Off) callback();
			nodeServer.unref();
			closed = true;
		});
		NodeSync.wait(() -> closed);
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
		this.socket.on(Timeout, () -> this.socket.destroy());
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
