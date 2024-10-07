package weblink._internal;

import haxe.io.BytesBuffer;

final class BytesBufferTools {

	public static inline function clear(buffer:BytesBuffer) {
		@:privateAccess buffer.pos = 0;
	}
}
