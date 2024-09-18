package security;

import buddy.BuddySuite;
import haxe.Http;
import haxe.Json;
import weblink.Weblink;
import weblink.security.Jwks;

using StringTools;
using buddy.Should;

class JwksSuite extends BuddySuite {
	private var weblink:Weblink;

	public function new() {
		describe("Jwks", {
			final knownKey:Jwk = {
				e: "AQAB",
				n: "iwlNcEM5m5Dy7bm_X1ZTJthzD_KIWpJ3gD79U-lt6fhO3Dyt9lqo447RyseEc1ZCUBDlpr7jTqlb3ZAeQb-sVw",
				kid: "47ce2098-311c-436d-ad1d-7379db3ac2d5",
				kty: "RSA"
			};

			it("endpoint can be queried", done -> {
				weblink = TestTools.createWeblink(app -> {
					final jwks = new Jwks();
					app.jwks(jwks);
				}, 2000);

				// When starting up the server, no keys should be known
				{
					final http = new Http("http://127.0.0.1:2000/jwks");
					http.onError = e -> throw e;
					http.onData = response -> {
						response.should.not.be(null);
						final set = Json.parse(response);
						Reflect.fields(set).length.should.be(1);
						final keys = (Reflect.field(set, "keys") : Array<Any>);
						keys.length.should.be(0);
					};
					http.request(false);
				}

				// Upload our known key
				{
					final http = new Http("http://127.0.0.1:2000/jwks");
					http.setPostData(Json.stringify(knownKey));
					http.request(false);
				}

				// The server should now know and return our key
				{
					final http = new Http("http://127.0.0.1:2000/jwks");
					http.onError = e -> fail(e);
					http.onData = response -> {
						response.should.not.be(null);
						final set = Json.parse(response);
						Reflect.fields(set).length.should.be(1);
						final keys = (Reflect.field(set, "keys") : Array<Jwk>);
						keys.length.should.be(1);
						final key = keys[0];
						key.e.should.be(knownKey.e);
						key.n.should.be(knownKey.n);
						key.kid.should.be(knownKey.kid);
						key.kty.should.be(knownKey.kty);
						done();
					};
					http.request(false);
				}
			});

			afterEach({
				weblink?.close();
			});
		});
	}
}
