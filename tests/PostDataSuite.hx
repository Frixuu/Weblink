import buddy.BuddySuite;
import weblink.PostData;

using TestTools;
using buddy.Should;

class PostDataSuite extends BuddySuite {
	public function new() {
		describe("URL-encoded data", {
			it("can be parsed if valid", {
				final map = PostData.parse("toto=1&tata=plop");
				Lambda.count(map).should.be(2);
				map.get("toto").should.be("1");
				map.get("tata").should.be("plop");
			});
			it("without values is being ignored", {
				final map = PostData.parse("alice&bob");
				Lambda.count(map).should.be(0);
			});
			it("does not throw if empty", {
				final map = PostData.parse("");
				Lambda.count(map).should.be(0);
			});
		});
	}
}
