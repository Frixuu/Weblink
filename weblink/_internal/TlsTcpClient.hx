package weblink._internal;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import sys.ssl.Context;
import weblink.tcp.ITcpClient;
import weblink.tcp.ITcpHandler;

using weblink._internal.BytesBufferTools;

@:nullSafety(StrictThreaded)
final class TlsTcpClient implements ITcpClient {

	private final innerClient:ITcpClient;
	private final tlsContext:Context;
	private final bufferOutgoingNotEncoded:BytesBuffer;
	private final tlsState:TlsTcpHandler;

	public var handler(get, set):Null<ITcpHandler>;

	private inline function get_handler():Null<ITcpHandler>
		return this.innerClient.handler;

	private inline function set_handler(value:Null<ITcpHandler>):Null<ITcpHandler>
		return this.innerClient.handler = value;

	public function new(innerClient:ITcpClient, tlsContext:Context, tlsState:TlsTcpHandler) {
		this.innerClient = innerClient;
		this.tlsContext = tlsContext;
		this.tlsState = tlsState;
		this.bufferOutgoingNotEncoded = new BytesBuffer();
	}

	public function startReading() {
		this.innerClient.startReading();
	}

	public function writeBytes(bytes:Bytes) {

		final bufferOut = this.bufferOutgoingNotEncoded;
		bufferOut.add(bytes);

		if (!this.tlsState.handshakeIfNecessary()) return;

		final sourceLength = bytes.length;
		final sentLength = this.tlsContext.send(hl.Bytes.fromBytes(bytes), 0, sourceLength);
		switch (sentLength) {
			case -1:
				throw "like it's libuv how is this blocking?";
			case 0:
				throw "how did you send 0 bytes???";
			case errorCode if (errorCode < 0):
				throw 'TLS error $errorCode';
		}
	}

	public function closeAsync(?callback:() -> Void):Bool {
		return this.innerClient.closeAsync(callback);
	}
}
