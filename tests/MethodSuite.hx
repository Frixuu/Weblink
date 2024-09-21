import buddy.BuddySuite;
import haxe.Http;
import haxe.io.Bytes;
import js.Syntax;
import js.lib.Promise;
import js.node.Timers;
import jsasync.JSAsync;
import jsasync.JSAsyncTools;
import promhx.Deferred;
import weblink.Weblink;

using TestTools;
using buddy.Should;

class MethodSuite extends BuddySuite {
	private var app:Weblink;

	public function new() {
		describe("Methods", {
			timeoutMs = 10000;
			it("do not get confused with each other", (done) -> {
				new Promise(untyped js.Syntax.code("async {0}", ((resolve, _) -> {
					app = new Weblink();
					app.get("/", (_, response) -> response.send("GET"));
					app.post("/", (request, response) -> response.send('POST ${request.data}'));
					app.listenTestMode(2000);

					{
						final response = JSAsyncTools.jsawait("http://127.0.0.1:2000".GET());
						response.should.be("GET");
					}

					{
						final data = Bytes.ofString(Std.string(Std.random(10 * 1000))).toHex();
						final http = new Http("http://127.0.0.1:2000");
						http.onError = e -> throw e;
						http.onData = response -> {
							response.should.be('POST ${data}');
							resolve(null);
						};
						http.setPostData(data);
						http.request(true);
					}
				}))).then(_ -> {
					done();
				});
			});

			afterEach({
				// app?.close();
			});
		});
	}
}
