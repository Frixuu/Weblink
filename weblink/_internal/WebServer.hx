package weblink._internal;

import sys.net.Host;
import sys.ssl.Certificate;
import sys.ssl.Context.Config;
import sys.ssl.Key;
import weblink._internal.Http11TcpHandler;
import weblink._internal.TlsTcpHandler;
import weblink._internal.hashlink.mbedtls.AuthMode;
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

	private var tlsConfig:Config;

	private var ownCert:Certificate;
	private var ownKey:Key;

	/**
		Creates a new web server instance.
	**/
	public function new(app:Weblink) {
		this.parent = app;

		this.tlsConfig = new Config(true);

		final caCert = Certificate.loadDefaults();
		trace('caCert: ${caCert.commonName}');
		this.tlsConfig.setCa(@:privateAccess caCert.__x);

		this.ownCert = Certificate.loadFile("cert.pem");
		final cert = this.ownCert;
		trace('cert: ${cert.commonName}');

		this.ownKey = Key.loadFile("key.pem", false, "1234");
		final key = this.ownKey;
		trace('key: ${key}');

		this.tlsConfig.setCert(@:privateAccess cert.__x, @:privateAccess key.__k);
		this.tlsConfig.setVerify(AuthMode.Optional);

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
			// client.handler = new Http11TcpHandler(this.parent, client);
			client.handler = new TlsTcpHandler(client, new Http11TcpHandler(this.parent, client), this.tlsConfig);
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
		this.tcpServer.closeAsync(() -> {
			@:nullSafety(Off) callback();
			this.tlsConfig.close();
			// this.tlsConfig = null;
		});
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
