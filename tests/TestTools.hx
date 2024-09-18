package;

import haxe.Http;
import weblink.Weblink;

final class TestTools {
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
}
