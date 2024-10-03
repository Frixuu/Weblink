package weblink._internal.hashlink;

#if hl
import hl.uv.Loop;
import hl.uv.Tcp;
import sys.net.Host;

/**
	Libuv handle to a TCP stream or server.
**/
@:forward
@:notNull
@:nullSafety(StrictThreaded)
abstract UvTcpHandle(UvStreamHandle) to UvStreamHandle {

	/**
		Enable or disable TCP_NODELAY for this socket.
	**/
	public var noDelay(never, set):Bool;

	/**
		Enables TCP_NODELAY by disabling Nagle's algorithm, or vice versa.
	**/
	private inline function set_noDelay(value:Bool):Bool {
		@:privateAccess Tcp.tcp_nodelay_wrap(cast this, value);
		return value;
	}

	/**
		Initializes a new handle.
		@param loop The loop the handle will be bound to.
	**/
	public static inline function initWrapOrThrow(loop:Loop):UvTcpHandle {

		final handle:Null<UvTcpHandle> = cast @:privateAccess Tcp.tcp_init_wrap(loop);
		if (handle != null) {
			return handle;
		}

		// Hashlink bindings do not expose libuv error codes for this operation
		throw new UvException("Libuv TCP handle could not be initialized");
	}

	/**
		If a client connection is initiated,
		tries to set up a handle for the TCP client socket.
	**/
	public inline function acceptOrThrow():UvTcpHandle {

		final client:Null<UvTcpHandle> = cast @:privateAccess Tcp.tcp_accept_wrap(cast this);
		if (client != null) {
			return client;
		}

		// Hashlink bindings do not expose libuv error codes for this operation
		throw new UvException("Could not accept TCP connection (called twice in a row?)");
	}

	/**
		Tries to bind the handle to an address and port.
	**/
	public inline function bindOrThrow(host:Host, port:Int) {
		final success = @:privateAccess Tcp.tcp_bind_wrap(cast this, host.ip, port);
		if (!success) {
			// Hashlink bindings do not expose libuv error codes for this operation
			throw new UvException('Could not bind libuv TCP socket to $host:$port (port in use?)');
		}
	}
}
#end
