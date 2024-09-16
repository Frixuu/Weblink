package security;

import buddy.BuddySuite;
import weblink.security.Sign;

using buddy.Should;

class JwtSigningSuite extends BuddySuite {
	public function new() {
		describe("Signing", {
			describe("with HS256", {
				it("is verifiable with the right secret key", {
					final payload = "data";
					final signature = Sign.sign(payload, "secret", "HS256");
					Sign.verify(payload, signature, "secret", "HS256").should.be(true);
				});
				it("is not verifiable with the wrong secret key", {
					final payload = "data";
					final signature = Sign.sign(payload, "secret", "HS256");
					Sign.verify(payload, signature, "another", "HS256").should.be(false);
				});
			});
			it("fails when an unsupported algorithm is requested", {
				final payload = "data";
				(() -> Sign.sign(payload, "secret", "SOMETHING")).should.throwAnything();
			});
		});
	}
}
