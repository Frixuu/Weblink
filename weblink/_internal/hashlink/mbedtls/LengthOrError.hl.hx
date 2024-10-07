package weblink._internal.hashlink.mbedtls;

enum abstract LengthOrError(Int) from Int to Int {
	public var Closed = 0;
	public var WouldBlock = -2;
	public var Eof = -29312;
}
