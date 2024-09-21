import buddy.BuddySuite;
import weblink.Weblink;

using TestTools;
using buddy.Should;

class MiddlewareSuite extends BuddySuite {
	private var app:Weblink;

	public function new() {
		describe("Middleware", {
			it("is being applied in the correct order", {
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
				app.listenTestMode(2000);

				final response = "http://127.0.0.1:2000".GET();
				response.should.be("bazbarfoo");
			});

			it("should be able to short-circuit", {
				app = new Weblink();
				app.get("/", (_, _) -> fail("default handler should not be called"), next -> {
					return (_, res) -> res.send("foo");
				});
				app.listenTestMode(2000);

				final response = "http://127.0.0.1:2000".GET();
				response.should.be("foo");
			});

			afterEach({
				app?.close();
			});
		});
	}
}
