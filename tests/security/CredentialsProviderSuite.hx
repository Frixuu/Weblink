package security;

import buddy.BuddySuite;
import haxe.Json;
import weblink.Weblink;
import weblink.security.CredentialsProvider;

using TestTools;
using buddy.Should;

class CredentialsProviderSuite extends BuddySuite {
	private var app:Weblink;

	public function new() {
		describe("Credentials provider", {
			it("returns sample data", {
				app = new Weblink();
				app.users(new CredentialsProvider());
				app.listenTestMode(2000);

				final response = Json.parse("http://127.0.0.1:2000/users".GET());
				Reflect.fields(response).length.should.be(1);
				final users = (Reflect.field(response, "users") : Array<Dynamic>);
				users.length.should.be(1);
				final user:Dynamic = users[0];
				user.should.not.be(null);
				user.username.should.be("johndoe");
				user.email.should.be("johndoe@example.com");
				user.full_name.should.be("John Doe");
				user.disabled.should.be(false);
			});

			afterEach({
				app?.close();
			});
		});
	}
}
