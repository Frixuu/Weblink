package weblink._internal;

import sys.net.Host;
import weblink._internal.Http11TcpHandler;
import weblink.tcp.ITcpClient;
import weblink.tcp.ITcpServer;
#if hl
import weblink._internal.hashlink.HashlinkTcpServer;
#end
#if (target.threaded)
import sys.thread.Lock;
#end

/**
	An internal web server.
**/
@:nullSafety(StrictThreaded)
class WebServer {

	/**
		The inner TCP server.
	**/
	private var tcpServer:ITcpServer;

	/**
		The Weblink application.
	**/
	private var parent:Weblink;

	/**
		Creates a new web server instance.
	**/
	public function new(app:Weblink) {
		this.parent = app;
		#if hl
		this.tcpServer = new HashlinkTcpServer();
		#else
		#error "Weblink does not support your target yet"
		#end
	}

	public function listen(host:Host, port:Int, blocking:Bool) {

		// Even if we don't want to block,
		// we'd like it if the server is ready to accept connections
		// after this method returns.
		#if (target.threaded)
		final startLock = new Lock();
		#end

		this.tcpServer.startAsync(host, port, (client:ITcpClient) -> {
			client.handler = new Http11TcpHandler(this.parent, client);
		}, () -> {
			#if (target.threaded)
			startLock.release();
			#end
		});

		// Wait until the server is ready
		#if (target.threaded)
		startLock.wait(60.0);
		#end

		// If the caller wants us to block,
		// we also have to wait until the server eventually closes.
		if (blocking) {
			#if hl
			final hashlinkServer:HashlinkTcpServer = cast this.tcpServer;
			@:privateAccess hashlinkServer.closeLock.wait();
			#end
		}
	}

	public function close(?callback:() -> Void) {
		this.closeAsync(callback);
	}

	public function closeAsync(?callback:() -> Void) {
		this.tcpServer.closeAsync(callback);
	}

	public function closeSync() {
		#if (target.threaded)
		final lock = new Lock();
		this.closeAsync(() -> lock.release());
		if (!lock.wait(60.0)) {
			trace("Server close timeout");
		}
		#end
	}
}
