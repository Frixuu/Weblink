package weblink._internal.hashlink.mbedtls;

import sys.ssl.Context;

@:nullSafety(StrictThreaded)
final class ContextTools {

	public static inline function setBio<T>(
		tlsContext:Context,
		bioContext:T,
		customRecv:Bio.RecvCallback<T>,
		customSend:Bio.SendCallback<T>
	) {
		final array = Bio.TypedArray.create(bioContext, customRecv, customSend);
		ContextTools.setBioImpl(tlsContext, array);
	}

	@:hlNative("ssl", "ssl_set_bio")
	static function setBioImpl(tlsContext:Context, bio:Dynamic):Void {}
}
