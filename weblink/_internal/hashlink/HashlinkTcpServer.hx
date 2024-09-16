package weblink._internal.hashlink;

import sys.thread.Lock;
#if hl
import haxe.MainLoop;
import haxe.io.Bytes;
import hl.uv.Loop;
import sys.net.Host;
import weblink._internal.TcpServer;
import weblink._internal.hashlink.UvStreamHandle;
import weblink._internal.hashlink.UvTcpHandle;

final class HashlinkTcpServer extends TcpServer {
	private var uvLoop:Loop;
	private var serverHandle:UvTcpHandle;

	public function new() {
		this.uvLoop = Loop.getDefault() ?? throw "cannot get or init a default loop";
		this.serverHandle = new UvTcpHandle(this.uvLoop);
		this.serverHandle.setNodelay(true);
	}

	public function listen(host:Host, port:Int, callback:(client:TcpServer.ClientHandle) -> Void) {
		this.serverHandle.bind(host, port);
		this.serverHandle.listen(100, () -> {
			final client = this.serverHandle.accept() ?? return;
			final handle = new ClientHandle(client);
			callback(handle);
		});
	}

	public override function poll():Bool {
		super.poll();
		@:privateAccess MainLoop.tick(); // for timers
		this.uvLoop.run(NoWait);
		return true;
	}

	public override function close(?callback:() -> Void) {
		final lock = new Lock();
		final handle = this.serverHandle;
		@:nullSafety(Off) this.serverHandle = null;
		handle.close(() -> {
			if (callback != null) {
				@:nullSafety(Off) callback();
			}
			this.uvLoop.stop();
			lock.release();
		});
		lock.wait(30);
	}
}

final class ClientHandle extends TcpServer.ClientHandle {
	private var handle:UvStreamHandle;

	public inline function new(handle:UvStreamHandle) {
		this.handle = handle;
	}

	public function startReading(callback:(data:Null<Bytes>) -> Void):Void {
		this.handle.readStart(callback);
	}

	public function writeBytes(bytes:Bytes) {
		this.handle.writeBytes(bytes);
	}

	public function close(?callback:() -> Void) {
		this.handle.close(callback);
		@:nullSafety(Off) this.handle = null;
	}
}
#end
