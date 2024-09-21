import buddy.BuddySuite;
import weblink.Projection;
import weblink.security.OAuth.User;
import weblink.security.OAuth.UserInDB;

using TestTools;
using buddy.Should;

class ReflectionSuite extends BuddySuite {
	public function new() {
		describe("Projection between classes", {
			it("works", {
				final original = new UserInDB();
				original.username = "Example";
				original.email = "example@example.com";
				original.full_name = "Example Example";
				original.disabled = false;
				original.hashed_password = "example-password";

				final output = Projection.convert(original, User);
				output.should.beType(User);
				output.should.not.beType(UserInDB);
				Reflect.field(output, "username").should.be("Example");
				Reflect.field(output, "hashed_password").should.be(null);
			});
		});
	}
}
