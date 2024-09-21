package;

import haxe.Constraints.Function;
import js.lib.Promise;
import js.node.Timers;
import jsasync.IJSAsync;
import jsasync.JSAsyncTools;
import weblink.Weblink;
#if (nodejs)
import js.node.events.EventEmitter;
#end

final class TestTools implements IJSAsync {
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

	@:jsasync
	public static function GET(url:String):Promise<Null<String>> {
		var response:Null<String> = null;
		#if (nodejs)
		final workerCode = '
		
			import { workerData, parentPort } from "node:worker_threads";

			console.log("worker: started");
			const url = workerData.url;
			const res = await fetch(url);
			console.log("worker: fetched a response");
			parentPort.postMessage(await res.text());

			parentPort.on("message", buffer => {
				console.log("worker: got a sharedarraybuffer");
				const arr = new Int32Array(buffer);
				Atomics.store(arr, 0, 1);
				Atomics.notify(arr, 0);
			});
		';

		final requestWorker = new NodeWorker(workerCode, {
			name: "HTTP request",
			eval: true,
			workerData: {url: url}
		});

		requestWorker.on(Message, value -> {
			trace('main: worker sent us a HTTP response: ${value}');
			response = value;
		});

		var buffer = new js.lib.SharedArrayBuffer(js.lib.Int32Array.BYTES_PER_ELEMENT);
		trace('main: sending a buffer to a worker');
		requestWorker.postMessage(buffer);
		trace('main: waiting for atomics');
		var spins = 10;
		do {
			final result = js.lib.Atomics.wait(new js.lib.Int32Array(buffer), 0, 0, 10);
			if (result != TimedOut)
				break;
			spins--;
			trace("before await");
			JSAsyncTools.jsawait(new Promise((r, _) -> {
				Timers.setTimeout(r, 0);
				trace("in promise");
			}));
		} while (spins > 0);
		#end
		return response;
	}
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
