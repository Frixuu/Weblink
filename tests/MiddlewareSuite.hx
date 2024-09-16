import buddy.BuddySuite;
import haxe.Http;
import weblink.Weblink;

using buddy.Should;

class MiddlewareSuite extends BuddySuite {
	private var weblink:Weblink;

	public function new() {
		describe("Middleware", {
			it("is being applied in the correct order", done -> {
				final state = ["1", "2", "3"];
				weblink = TestTools.createWeblink(app -> {
					app.use((_, _) -> {
						state[0] = "foo";
						state[1] = "foo";
						state[2] = "foo";
					});
					app.use((_, _) -> {
						state[0] = "bar";
						state[1] = "bar";
					});
					app.use((_, _) -> {
						state[0] = "baz";
					});

					app.get("/", (_, res) -> res.send('${state[0]}${state[1]}${state[2]}'));
				}, 2000);

				final http = new Http("http://127.0.0.1:2000/");
				http.onError = e -> fail(e);
				http.onData = response -> {
					response.should.be("bazbarfoo");
					done();
				};
				http.request(false);
			});

			it("should be able to short-circuit", done -> {
				weblink = TestTools.createWeblink(app -> {
					app.get("/", (_, _) -> fail("default handler should not be called"), next -> {
						return (_, res) -> res.send("foo");
					});
				}, 2000);

				final http = new Http("http://127.0.0.1:2000/");
				http.onError = e -> fail(e);
				http.onData = response -> {
					response.should.be("foo");
					done();
				};
				http.request(false);
			});

			afterEach({
				weblink?.close();
			});
		});
	}
}
