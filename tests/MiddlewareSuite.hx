import buddy.BuddySuite;
import weblink.Weblink;

using buddy.Should;

class MiddlewareSuite extends BuddySuite {
	private var app:Weblink;

	public function new() {
		describe("Middleware", {
			it("is being applied in the correct order", done -> {
				final state = ["1", "2", "3"];
				app = new Weblink();
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
				app.listen(2000, false);

				TestTools.request(app, "http://0.0.0.0:2000/", http -> {
					http.onError = e -> fail(e);
					http.onData = response -> {
						response.should.be("bazbarfoo");
						done();
					};
					http.request(false);
				});
			});

			it("should be able to short-circuit", done -> {
				app = new Weblink();
				app.get("/", (_, _) -> fail("default handler should not be called"), next -> {
					return (_, res) -> res.send("foo");
				});
				app.listen(2000, false);

				TestTools.request(app, "http://0.0.0.0:2000/", http -> {
					http.onError = e -> fail(e);
					http.onData = response -> {
						response.should.be("foo");
						done();
					};
					http.request(false);
				});
			});

			afterEach({
				app?.close();
			});
		});
	}
}
