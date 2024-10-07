package weblink._internal.hashlink;

#if hl
import haxe.io.Bytes;
import hl.Gc;
import sys.thread.Thread;
import weblink._internal.hashlink.UvStreamHandle.ReadStartData;
import weblink.tcp.ITcpClient;
import weblink.tcp.ITcpHandler;

@:nullSafety(StrictThreaded)
final class HashlinkTcpClient implements ITcpClient {

	/**
		The TCP server that created this client.
	**/
	private var server:Null<HashlinkTcpServer>;

	/**
		The libuv socket handle representing this client.
	**/
	private var innerClient:Null<UvTcpHandle>;

	/** 
		TCP handler for incoming data.
	**/
	@:isVar
	public var handler(get, set):Null<ITcpHandler>;

	private inline function get_handler():Null<ITcpHandler>
		return @:bypassAccessor this.handler;

	private inline function set_handler(value:Null<ITcpHandler>):Null<ITcpHandler>
		return @:bypassAccessor this.handler = value;

	public function new(server:HashlinkTcpServer, innerClient:UvTcpHandle) {
		this.server = server;
		this.innerClient = innerClient;
	}

	public function startReading() {

		final innerClient = this.innerClient;
		if (innerClient == null) {
			throw "startReading() called on a closed client";
		}

		innerClient.readStartOrThrow(this.readImpl);
	}

	private function readImpl(data:ReadStartData) {
		Gc.enable(true);
		switch (data) {
			case Data(bytes):
				final handler = this.handler;
				if (handler != null) {
					try {
						handler.onData(bytes);
					} catch (e) {
						trace(e.details());
						this.closeAsync();
					}
				} else {
					this.closeAsync();
				}
			case Error(code):
				if (code == Eof) {
					this.closeAsync();
				} else {
					trace('cannot read from libuv TCP socket, error $code');
					this.closeAsync();
				}
		}
		Gc.enable(false);
	}

	public function writeBytes(bytes:Bytes) {

		final innerClient = this.innerClient;
		if (innerClient == null) {
			throw "writeBytes() called on a closed client";
		}

		innerClient.writeBytesOrThrow(bytes);
	}

	public function closeAsync(?callback:() -> Void):Bool {

		// The client can be requested to close only once
		final innerClient = this.innerClient;
		this.innerClient = null;
		if (innerClient == null) {
			return false;
		}

		final server = this.server;
		this.server = null;
		final serverThread:Null<Thread> = {
			if (server == null) {
				null;
			} else {
				@:privateAccess server.serverThread;
			}
		};

		final callbackCombined = () -> {

			final handler = this.handler;
			this.handler = null;
			if (handler != null) {
				handler.onDisconnected();
			}

			if (callback != null) {
				@:nullSafety(Off) callback();
			}
		};

		// uv_close must be called from the libuv loop thread
		final currentThread = Thread.current();
		if (serverThread != null && serverThread != currentThread) {
			final serverEvents = @:nullSafety(Off) serverThread.events;
			@:nullSafety(Off) serverEvents.run(() -> innerClient.closeAsync(callbackCombined));
		} else {
			innerClient.closeAsync(callbackCombined);
		}

		return true;
	}
}
#end
