import buddy.BuddySuite;
import haxe.Http;
import weblink.Cookie;
import weblink.Weblink;

using TestTools;
using buddy.Should;

class CookieSuite extends BuddySuite {
	private var app:Weblink;

	public function new() {
		describe("Cookies", {
			it("get sent with the responses", done -> {
				app = new Weblink();
				app.get("/", (request, response) -> {
					response.cookies.add(new Cookie("foo", "bar"));
					response.send("whatever");
				});
				app.listenTestMode(2000);

				final http = new Http("http://localhost:2000");
				http.onStatus = status -> status.should.be(200);
				http.onData = _ -> {
					final headers = http.responseHeaders;
					final header = headers.get("Set-Cookie") ?? headers.get("set-cookie");
					header.should.be("foo=bar");
					done();
				};
				http.request(false);
			});

			afterEach({
				app?.close();
			});
		});
	}
}
