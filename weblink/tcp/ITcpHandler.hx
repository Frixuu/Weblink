package weblink.tcp;

import haxe.io.Bytes;

/**
	A handler for incoming TCP data.

	The implementations should be stateful and may interpret the data in any way they like,
	including parsing it as HTTP requests, WebSocket frames, etc.
**/
@:nullSafety(StrictThreaded)
interface ITcpHandler {

	/**
		Consumes incoming data.

		Note: TCP does not deliver messages. It delivers bytes.
		The handler is responsible for accumulating and parsing them as messages.
		@param data Incoming data.
	**/
	public function onData(data:Bytes):Void;

	/**
		Called when the connection is closed.
		The handler can clean up resources.
	**/
	public function onDisconnected():Void;
}
