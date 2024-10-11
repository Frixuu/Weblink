package weblink._internal.hashlink.mbedtls;

import hl.NativeArray;
import sys.ssl.Context;

@:nullSafety(StrictThreaded)
final class ContextTools {

	public static inline function setBio<T>(
		tlsContext:Context,
		sharedParam:T,
		customRecv:(sharedParam:T, buffer:hl.Bytes, bufferLength:Int) -> LengthOrError,
		customSend:(sharedParam:T, buffer:hl.Bytes, bufferLength:Int) -> LengthOrError
	) {
		final array = new NativeArray<Dynamic>(3);
		array[0] = sharedParam;
		array[1] = customRecv;
		array[2] = customSend;
		ContextTools.setBioImpl(tlsContext, array);
	}

	@:hlNative("ssl", "ssl_set_bio")
	static function setBioImpl(tlsContext:Context, bio:Dynamic):Void {}
}
