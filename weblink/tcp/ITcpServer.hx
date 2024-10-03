package weblink.tcp;

import sys.net.Host;

/**
	A handle for a TCP server.
**/
@:nullSafety(StrictThreaded)
interface ITcpServer {

	/**
		Starts listening for incoming connections.
		@param host The IPv4 address to listen on.
		@param port The port to bind to.
		@param configureClient A callback to configure the client handler.
		@param callback Optional callback to be called when the server is ready.
	**/
	public function startAsync(
		host:Host,
		port:Int,
		configureClient:(client:ITcpClient) -> Void,
		?callback:() -> Void
	):Void;

	/**
		Schedules the server to be closed. This call is non-blocking.
		@param callback Optional callback to be called when the server is closed.
		@return True if the request was scheduled, false if the server is already (being) closed.
	**/
	public function closeAsync(?callback:() -> Void):Bool;
}
