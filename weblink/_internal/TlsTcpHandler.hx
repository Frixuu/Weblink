package weblink._internal;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import sys.ssl.Context;
import weblink.tcp.ITcpClient;
import weblink.tcp.ITcpHandler;

using weblink._internal.BytesBufferTools;
using weblink._internal.hashlink.mbedtls.ContextTools;
using weblink._internal.hashlink.mbedtls.LengthOrError;

// @:nullSafety(StrictThreaded)
final class TlsTcpHandler implements ITcpHandler {

	private var client:Null<ITcpClient>;
	private var tlsContext:Null<Context>;
	private var innerHandler:Null<ITcpHandler>;
	private var bufferIncomingEncoded:Null<BytesBuffer>;
	private var handshakeDone:Bool = false;

	public function new(client:ITcpClient, innerHandler:ITcpHandler, tlsConfig:Config) {

		this.client = client;

		this.bufferIncomingEncoded = new BytesBuffer();
		this.tlsContext = new Context(tlsConfig);
		if (this.tlsContext == null) {
			throw "TLS context is null";
		}

		this.tlsContext.setBio(this, (
			handler,
			buffer,
			length
		) -> handler.receiveImpl(buffer, length),
			(handler, buffer, length) -> handler.sendImpl(buffer, length));

		this.innerHandler = innerHandler;
		Reflect.setProperty(innerHandler, "client", new TlsTcpClient(client, tlsContext, this));
	}

	public function receiveImpl(targetBuffer:hl.Bytes, targetLength:Int):LengthOrError {

		trace("recv callback called!");
		final sourceBuffer = this.bufferIncomingEncoded;
		if (sourceBuffer == null) {
			trace("receiveImpl called on a closed handler");
			return Closed;
		}

		final length = sourceBuffer.length;
		if (length == 0) {
			trace("receiveImpl called on an empty buffer (would block)");
			return WouldBlock;
		}

		if (length <= targetLength) {
			targetBuffer.blit(0, sourceBuffer.getBytes(), 0, length);
			sourceBuffer.clear();
			trace('receiveImpl returned length $length');
			return length;
		} else {
			targetBuffer.blit(0, sourceBuffer.getBytes(), 0, targetLength);
			final remainingLength = length - targetLength;
			final remaining = new hl.Bytes(remainingLength);
			remaining.blit(0, sourceBuffer.getBytes(), targetLength, remainingLength);
			sourceBuffer.clear();
			sourceBuffer.add(remaining.toBytes(remainingLength));
			trace('receiveImpl returned length $targetLength');
			return targetLength;
		}
	}

	public function sendImpl(bufferEncoded:hl.Bytes, length:Int):LengthOrError {

		trace("send callback called!");
		final client = this.client;
		if (client == null) {
			return Eof;
		}

		client.writeBytes(bufferEncoded.toBytes(length));
		return length;
	}

	public function onData(data:Bytes) {

		trace('onData: (length: ${data.length}) $data');

		final buffer = this.bufferIncomingEncoded;
		if (buffer == null) {
			throw "cannot consume data if the client allegedly disconnected";
		}

		buffer.add(data);

		if (!this.handshakeIfNecessary()) return;

		final bufferDecoded = new hl.Bytes(buffer.length * 2);

		final tlsContext = this.tlsContext;
		if (tlsContext == null) {
			throw "TLS context is null";
		}

		while (true) {
			final lengthOrCode = tlsContext.recv(bufferDecoded, 0, buffer.length * 2);
			switch (lengthOrCode) {
				case -1:
					trace("just filled the buffer, how is it blocking?");
					break;
				case 0:
					trace("how did you receive 0 bytes???");
					break;
				case errorCode if (errorCode < 0):
					throw 'TLS error $errorCode';
				case length:
					@:nullSafety(Off) this.innerHandler.onData(bufferDecoded.toBytes(length));
			}
		}
	}

	public function handshakeIfNecessary():Bool {
		if (!this.handshakeDone) {

			final tlsContext = this.tlsContext;
			if (tlsContext == null) {
				throw "TLS context is null";
			}

			final result = tlsContext.handshake();
			if (result == 0) {
				this.handshakeDone = true;
				return true;
			} else if (result == -1) {
				return false;
			} else {
				throw new haxe.io.Eof();
			}
			return false;
		}
		return true;
	}

	public function onDisconnected() {

		this.client = null;
		this.bufferIncomingEncoded = null;

		final innerHandler = this.innerHandler;
		if (innerHandler != null) {
			innerHandler.onDisconnected();
			this.innerHandler = null;
		}

		final tlsContext = this.tlsContext;
		if (tlsContext != null) {
			// @:nullSafety(Off) tlsContext.setBio(null, null, null);
			tlsContext.close();
			this.tlsContext = null;
		}
	}
}
