package security;

import buddy.BuddySuite;
import weblink.security.Jwt;

using buddy.Should;

class JwtSuite extends BuddySuite {
	public function new() {
		describe("JSON Web Token", {
			it("creation fails with a bad algorithm", {
				(() -> {
					Jwt.create_access_token({sub: "alice"}, "secret", "bad algorithm", 30);
				}).should.throwAnything();
			});
			it("decode fails with a bad algorithm", {
				final secret = "secret";
				final accessToken = Jwt.create_access_token({sub: "alice"}, secret, "HS256", 30);
				(() -> {
					Jwt.decode(accessToken, secret, "bad algorithm");
				}).should.throwAnything();
			});
			it("decode fails with a bad secret", {
				final algo = "HS256";
				final accessToken = Jwt.create_access_token({sub: "alice"}, "good secret", algo, 30);
				(() -> {
					Jwt.decode(accessToken, "bad secret", algo);
				}).should.throwAnything();
			});
			it("decode succeeds otherwise", {
				final username = "alice";
				final secret = "secret";
				final algorithm = "HS256";
				final expiresIn = 30;

				final accessToken = Jwt.create_access_token({sub: username}, secret, algorithm, expiresIn);
				accessToken.split(".").length.should.be(3);

				final token = Jwt.decode(accessToken, secret, algorithm);
				token.sub.should.be(username);
				final now = Date.now().getTime() / 1000;
				token.exp.should.beGreaterThan(now);
				token.exp.should.beLessThan(now + 2 * (expiresIn * 60));
			});
		});
	}
}
