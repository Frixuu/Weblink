package weblink._internal.hashlink;

#if hl
import haxe.io.Bytes;
import haxe.io.Eof;
import hl.uv.Stream;

@:forward
abstract UvStreamHandle(UvHandle) to UvHandle {
	public inline function listen(backlog:Int, callback:() -> Void) {
		if (this == null) {
			// For compatibility, throw EOF
			throw new Eof();
		}
		final retval = @:privateAccess Stream.stream_listen(this, backlog, callback);

		// Hashlink bindings do not expose libuv error codes.
		// For compatibility, assume error is EOF
		if (!retval)
			throw new Eof();
	}

	public inline function writeBytes(bytes:Bytes) {
		if (this == null) {
			// Connection closed. For compatibility, throw EOF
			throw new Eof();
		}

		final rawBytes = (bytes : hl.Bytes).offset(0);
		final len = bytes.length;
		final retval = @:privateAccess Stream.stream_write(this, rawBytes, len, cast null);

		if (!retval)
			// Cannot write. For compatibility, throw EOF
			throw new Eof();
	}

	public inline function writeString(string:String) {
		abstract.writeBytes(Bytes.ofString(string, UTF8));
	}

	public inline function readStart(readCallback:(data:Null<Bytes>) -> Void) {
		if (this == null) {
			// Connection closed. For compatibility, throw EOF
			throw new Eof();
		}

		final retval = @:privateAccess Stream.stream_read_start(this, (buffer, nRead) -> {
			if (nRead < 0) {
				readCallback(null);
			} else {
				readCallback(buffer.toBytes(nRead));
			}
		});

		if (!retval) {
			// Cannot start reading. For compatibility, throw EOF
			throw new Eof();
		}
	}
}
#end
