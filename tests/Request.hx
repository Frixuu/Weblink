import haxe.Http;

class Request {
	public static function main() {
		Sys.println("start test");
		var app = new weblink.Weblink();
		var data = haxe.io.Bytes.ofString(Std.string(Std.random(10 * 1000))).toHex();
		app.get("/", function(request, response) {
			response.send(data);
		});
		app.post("/", function(request, response) {
			response.send(data + request.data);
		});
		app.put("/", function(request, response) {
			response.send(data + request.data);
		});
		app.listen(2000, false);

		{
			var response = Http.requestUrl("http://localhost:2000");
			if (response != data)
				throw "post response data does not match: " + response + " data: " + data;
			var http = new Http("http://localhost:2000");
			http.setPostData(data);
			http.request(false);
			if (http.responseData != data + data)
				throw "post response data does not match: " + http.responseData + " data: " + data + data;
			app.close();
		}

		trace("done");
	}
}
