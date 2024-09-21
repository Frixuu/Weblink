package;

import weblink.Weblink;
#if (nodejs)
import haxe.Constraints.Function;
import js.html.Request;
import js.html.Response;
import js.lib.Promise;
import js.node.events.EventEmitter;
import sys.NodeSync;
#end

final class TestTools {
	/**
		If running on a threaded target (ie. Hashlink),
		creates the server in a separate thread and keeps polling it,
		so that our main testing thread can do HTTP requests.

		If running on a non-threaded target (ie. NodeJS),
		creates the server in the current thread and hopes for the best.
	**/
	public static function listenTestMode(app:Weblink, port:Int) {
		#if (target.threaded)
		final lock = new sys.thread.Lock();
		sys.thread.Thread.create(() -> {
			app.listen(port, false);
			lock.release();
			while (app.server.running) {
				app.server.update(false);
				Sys.sleep(0.1);
			}
		});
		lock.wait();
		#else
		app.listen(port, false);
		#end
	}

	public inline static function GET(url:String):String {
		return TestTools.requestBlocking(url, {post: false});
	}

	public inline static function POST(url:String, body:String):String {
		return TestTools.requestBlocking(url, {post: true, postBody: body});
	}

	#if (hl)
	private static function requestBlocking(url:String, opts:RequestOptions):String {
		final http = new haxe.Http(url);
		var responseString:Null<String> = null;
		http.onError = e -> throw e;
		http.onData = s -> responseString = s;
		if (opts.postBody != null) {
			http.setPostData(opts.postBody);
		}
		http.request(opts.post); // sys.Http#request reads sys.net.Sockets, which is blocking
		return responseString;
	}
	#elseif (nodejs)
	private static function requestBlocking(url:String, opts:RequestOptions):String {
		final eventEmitter:IEventEmitter = new EventEmitter();
		final request = new Request(url, {
			method: opts.post ? "POST" : "GET",
			body: opts.postBody
		});

		// fetch is not behind a flag since Node 18 and stable since Node 21
		final promise:Promise<Response> = untyped fetch(request);
		promise.then(response -> response.text())
			.then(text -> eventEmitter.emit("message", {value: text, error: null}))
			.catchError(e -> eventEmitter.emit("message", {value: null, error: e.message}));

		var response:Null<{value:Null<String>, error:Null<String>}> = null;
		eventEmitter.once("message", value -> {
			response = value;
		});

		// Calls deasync (native code package) to manually trigger UV event loop,
		// otherwise I/O macrotasks are not executed.
		// This behaviour can be kind of faked by making tests true async and simply awaiting fetch,
		// but current Haxe status does not make that easy to do idiomatically
		NodeSync.wait(() -> response != null);
		if (response.error == null && response.value != null) {
			return response.value;
		} else {
			throw response.error;
		}
	}
	#end
}

typedef RequestOptions = {
	post:Bool,
	?postBody:String,
}

#if (nodejs)
@:jsRequire("node:worker_threads", "Worker")
extern class NodeWorker extends EventEmitter<NodeWorker> {
	public function new(filenameOrScript:String, options:{}):Void;
	public function postMessage(message:Any):Void;
}

enum abstract WorkerEvent<T:Function>(Event<T>) to Event<T> {
	public var Message:WorkerEvent<(value:Dynamic) -> Void> = "message";
}
#end
