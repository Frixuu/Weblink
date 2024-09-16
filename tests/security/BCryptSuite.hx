package security;

import buddy.BuddySuite;
import weblink.security.BCryptPassword;

using buddy.Should;

class BCryptSuite extends BuddySuite {
	public function new() {
		describe("BCrypt", {
			it("hashes are verifiable", {
				final password = "secret";
				final hash = BCryptPassword.get_password_hash(password);
				BCryptPassword.verify_password(password, hash).should.be(true);
			});
		});
	}
}
