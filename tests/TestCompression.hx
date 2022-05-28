import haxe.Http;
import haxe.io.Bytes;
import haxe.zip.Compress;
import weblink.Compression;
import weblink.Weblink;

class TestCompression {
	public static function main() {
		trace("Starting Content-Encoding Test");
		var app = new weblink.Weblink();
		var data = "test";
		var bytes = haxe.io.Bytes.ofString(data);
		var compressedData = Compress.run(bytes, 9);
		app.get("/", function(request, response) {
			response.sendBytes(bytes);
		}, Compression.deflateCompressionMiddleware);
		app.listen(2000, false);

		sys.thread.Thread.create(() -> {
			var http = new Http("http://localhost:2000");
			var response:Bytes = null;
			http.onBytes = function(bytes) {
				response = bytes;
			}
			http.onError = function(e) {
				throw e;
			}
			http.request(false);
			if (response.compare(compressedData) != 0)
				throw "get response compressed data does not match: " + response + " compressedData: " + compressedData;
			app.close();
		});

		while (app.server.running) {
			app.server.update(false);
			Sys.sleep(0.2);
		}
		trace("done");
	}
}
