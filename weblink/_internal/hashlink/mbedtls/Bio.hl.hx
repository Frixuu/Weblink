package weblink._internal.hashlink.mbedtls;

import hl.NativeArray;

/**
	Receives data from the network.
	May receive fewer bytes than the length of the buffer.
**/
typedef RecvCallback<T> = (context:T, intoBuffer:hl.Bytes, bufferLength:Int) -> LengthOrError;

/**
	Sends data on the network.
	Can send fewer bytes than requested.
**/
typedef SendCallback<T> = (context:T, buffer:hl.Bytes, lengthToSend:Int) -> LengthOrError;

@:forward
@:transitive
abstract TypedArray<T>(NativeArray<Dynamic>) {
	private function new(repr:NativeArray<Dynamic>) {
		this = repr;
	}

	public inline static function create<T>(
		context:T,
		recv:RecvCallback<T>,
		send:SendCallback<T>
	):TypedArray<T> {
		final arr = new NativeArray<Dynamic>(3);
		arr[0] = context;
		arr[1] = recv;
		arr[2] = send;
		return new TypedArray(arr);
	}
}
