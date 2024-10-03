package weblink.tcp;

import haxe.io.Bytes;

/**
	A handle for a connected TCP client.
**/
@:nullSafety(StrictThreaded)
interface ITcpClient {

	/**
		Handler for incoming data.
		Can be specialized for HTTP/1.1, HTTP/2 or WebSocket protocols.

		When no handler is active when data is incoming,
		the connection should be closed.
	**/
	public var handler(default, default):Null<ITcpHandler>;

	/**
		Starts reading data from the client.
		The implementations should pass it to the registered handler.
	**/
	public function startReading():Void;

	/**
		Sends bytes to the client.
	**/
	public function writeBytes(bytes:Bytes):Void;

	/**
		Schedules the client to be disconnected. This call is non-blocking.
		@param callback Optional callback to be called when the client is disconnected.
		@return True if the request was scheduled, false if the client is already (being) closed.
	**/
	public function closeAsync(?callback:() -> Void):Bool;
}
