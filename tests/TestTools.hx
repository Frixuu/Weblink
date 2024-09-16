package;

import haxe.Http;
import haxe.Timer;
import weblink.Weblink;

final class TestTools {
	public static function request(app:Weblink, url:String, body:(http:Http) -> Void) {
		#if (target.threaded)
		sys.thread.Thread.create(() -> {
			while (app.server.running) {
				app.server.update(false);
				Sys.sleep(0.1);
			}
		});
		#end
		final http = new Http(url);
		body(http);
	}
}
