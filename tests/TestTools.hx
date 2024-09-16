package;

import haxe.Http;
import weblink.Weblink;

final class TestTools {
	public static function GET(url:String):String {
		final http = new Http(url);
		var responseString:Null<String> = null;
		http.onError = e -> throw e;
		http.onData = s -> responseString = s;
		http.request(false);
		return responseString;
	}

	public static function request(app:Weblink, url:String, body:(http:Http) -> Void) {
		TestTools.keepPollingIfThreaded(app);
		final http = new Http(url);
		body(http);
	}

	public static function createWeblink(fn:(app:Weblink) -> Void, port:Int):Weblink {
		final app = new Weblink();
		#if (target.threaded)
		final lock = new sys.thread.Lock();
		sys.thread.Thread.create(() -> {
			fn(app);
			app.listen(port, false);
			lock.release();
			while (app.server.running) {
				app.server.update(false);
				Sys.sleep(0.1);
			}
		});
		lock.wait();
		#else
		fn(app);
		app.listen(port, false);
		#end
		return app;
	}

	public static function keepPollingIfThreaded(app:Weblink) {
		#if (target.threaded)
		sys.thread.Thread.create(() -> {
			while (app.server.running) {
				app.server.update(false);
				Sys.sleep(0.1);
			}
		});
		#end
	}
}
