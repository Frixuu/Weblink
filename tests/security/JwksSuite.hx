package security;

import buddy.BuddySuite;
import haxe.Json;
import weblink.Weblink;
import weblink.security.Jwks;

using StringTools;
using TestTools;
using buddy.Should;

class JwksSuite extends BuddySuite {
	private var app:Weblink;

	public function new() {
		describe("Jwks", {
			final knownKey:Jwk = {
				e: "AQAB",
				n: "iwlNcEM5m5Dy7bm_X1ZTJthzD_KIWpJ3gD79U-lt6fhO3Dyt9lqo447RyseEc1ZCUBDlpr7jTqlb3ZAeQb-sVw",
				kid: "47ce2098-311c-436d-ad1d-7379db3ac2d5",
				kty: "RSA"
			};

			it("endpoint can be queried", {
				app = new Weblink();
				app.jwks(new Jwks());
				app.listenTestMode(2000);

				// When starting up the server, no keys should be known
				{
					final response = "http://127.0.0.1:2000/jwks".GET();
					final set = Json.parse(response);
					Reflect.fields(set).length.should.be(1);
					final keys = (Reflect.field(set, "keys") : Array<Any>);
					keys.length.should.be(0);
				}

				// Upload our known key
				{
					final _ = "http://127.0.0.1:2000/jwks".POST(Json.stringify(knownKey));
				}

				// The server should now know and return our key
				{
					final response = "http://127.0.0.1:2000/jwks".GET();
					final set = Json.parse(response);
					Reflect.fields(set).length.should.be(1);
					final keys = (Reflect.field(set, "keys") : Array<Jwk>);
					keys.length.should.be(1);
					final key = keys[0];
					key.e.should.be(knownKey.e);
					key.n.should.be(knownKey.n);
					key.kid.should.be(knownKey.kid);
					key.kty.should.be(knownKey.kty);
				}
			});

			afterEach({
				app?.close();
			});
		});
	}
}
