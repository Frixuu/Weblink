package weblink._internal.hashlink;

import haxe.io.Eof;
import hl.uv.Loop;
import hl.uv.Tcp;
import sys.net.Host;

@:forward
abstract UvTcpHandle(UvStreamHandle) to UvStreamHandle {
	public inline function new(loop:Loop) {
		this = cast @:privateAccess Tcp.tcp_init_wrap(loop);
		if (this == null) {
			throw "libuv handle could not be initialized";
		}
	}

	public inline function setNodelay(value:Bool) {
		@:privateAccess Tcp.tcp_nodelay_wrap(cast this, value);
	}

	public inline function accept():Null<UvStreamHandle> {
		if (this == null) {
			return null;
		}
		final client = @:privateAccess Tcp.tcp_accept_wrap(cast this);

		// Hashlink bindings do not expose libuv error codes.
		// For compatibility, assume error is EOF
		if (client == null)
			throw new Eof();

		return cast client;
	}

	public inline function bind(host:Host, port:Int) {
		final success = @:privateAccess Tcp.tcp_bind_wrap(cast this, host.ip, port);
		if (!success) {
			// for compatibility
			throw haxe.io.Error.Custom("Failed to bind socket to " + host + ":" + port);
		}
	}
}
