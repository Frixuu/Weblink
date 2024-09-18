package;

import weblink.Weblink;

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
}
