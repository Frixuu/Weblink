import buddy.BuddySuite;
import haxe.Http;
import haxe.io.Bytes;
import haxe.zip.Compress;
import weblink.Compression;
import weblink.Weblink;

using TestTools;
using buddy.Should;

class CompressionSuite extends BuddySuite {
	private var app:Weblink;

	public function new() {
		describe("Compression", {
			it("gets applied to responses (deflate)", done -> {
				final data = Bytes.ofString("Well-known test data");

				app = new Weblink();
				app.use(Compression.deflateCompressionMiddleware);
				app.get("/", (_, response) -> response.sendBytes(data));
				app.listenTestMode(2000);

				final http = new Http("http://localhost:2000");
				http.onError = e -> throw e;
				http.onBytes = bytes -> {
					final compressedData = Compress.run(data, 9);
					bytes.compare(compressedData).should.be(0);
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
