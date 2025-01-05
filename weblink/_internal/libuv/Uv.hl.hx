package weblink._internal.libuv;

/**
	@see https://github.com/HaxeFoundation/hashlink/blob/master/libs/uv/uv.c
**/
@:hlNative("uv")
final class Uv {
	@:native("close_handle")
	public static function close(handle:UvHandle, callback:Null<() -> Void>):Void {}

	@:native("stream_listen")
	public static function listen(handle:UvStreamHandle, backlog:Int, callback:() -> Void):Bool {
		return false;
	}

	@:native("stream_write")
	public static function write(handle:UvStreamHandle, buffer:hl.Bytes, bufferLength:Int, callback:Null<(success:Bool) -> Void>):Bool {
		return false;
	}

	@:native("stream_read_start")
	public static function readStart(handle:UvStreamHandle, callback:(buffer:hl.Bytes, nRead:Int) -> Void):Bool {
		return false;
	}

	@:native("tcp_nodelay_wrap")
	public static function tcpNodelay(handle:UvTcpHandle, enabled:Bool):Void {}

	@:native("tcp_init_wrap")
	public static function tcpInit(loop:UvLoop):Null<UvTcpHandle> {
		return null;
	}

	@:native("tcp_accept_wrap")
	public static function tcpAccept(server:UvTcpHandle):Null<UvTcpHandle> {
		return null;
	}

	@:native("tcp_bind_wrap")
	public static function tcpBind(handle:UvTcpHandle, ipv4Le:Int, port:Int):Bool {
		return false;
	}
}
