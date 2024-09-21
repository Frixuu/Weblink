import buddy.BuddySuite;
import haxe.io.Bytes;
import weblink.Weblink;

using TestTools;
using buddy.Should;

class MethodSuite extends BuddySuite {
	private var app:Weblink;

	public function new() {
		describe("Methods", {
			it("do not get confused with each other", {
				app = new Weblink();
				app.get("/", (_, response) -> response.send("GET"));
				app.post("/", (request, response) -> {
					response.send('POST ${request.data}');
				});
				app.listenTestMode(2000);

				{
					final response = "http://127.0.0.1:2000".GET();
					response.should.be("GET");
				}

				{
					final data = Bytes.ofString(Std.string(Std.random(10 * 1000))).toHex();
					final response = "http://127.0.0.1:2000".POST(data);
					response.should.be('POST ${data}');
				}

				{
					(() -> "http://127.0.0.1:2000/not-a-route".GET()).should.throwAnything();
				}
			});

			afterEach({
				app?.close();
			});
		});
	}
}
