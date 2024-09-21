import buddy.BuddySuite;
import weblink.Weblink;
import weblink._internal.ds.RadixTree;

using TestTools;
using buddy.Should;

class RadixTreeSuite extends BuddySuite {
	private var app:Weblink;

	public function new() {
		describe("Radix trees", {
			it("correctly match query routes", {
				final tree = new RadixTree<String>();
				tree.put("/", Get, "got index");
				tree.put("/food/fruit/apple", Get, "got apple");
				tree.put("/food/fruit/banana", Get, "got banana");
				tree.put("/food/fruit/banana", Post, "posted banana");
				tree.put("/food/:foodCategory/che", Get, "got che");
				tree.put("/blog/article/:slug", Get, "got article");

				tree.tryGet("/", Get).match(Found("got index", _)).should.be(true);

				tree.tryGet("/food/fruit/banana", Get).match(Found("got banana", _)).should.be(true);
				tree.tryGet("/food/fruit/banana", Post).match(Found("posted banana", _)).should.be(true);
				tree.tryGet("/food/fruit/banana", Patch).match(MissingMethod).should.be(true);
				tree.tryGet("/food/fruit/orange", Get).match(MissingRoute).should.be(true);

				tree.tryGet("/food/soup/che", Get).match(Found("got che", _)).should.be(true);
				tree.tryGet("/food/dessert/che", Get).match(Found("got che", _)).should.be(true);
				switch tree.tryGet("/food/fruit/che", Get) {
					case Found("got che", params):
						params.get("foodCategory").should.be("fruit");
						params.get("foobar").should.be(null);
					case _:
						fail("bad lookup result");
				}

				tree.tryGet("/blog/article/my-manifesto", Delete).match(MissingMethod).should.be(true);
				switch tree.tryGet("/blog/article/my-manifesto", Get) {
					case Found("got article", params):
						params.get("slug").should.be("my-manifesto");
						params.get("foodCategory").should.be(null);
					case _:
						fail("bad lookup result");
				}
				tree.tryGet("/blog/article/my-manifesto/comments", Get).match(MissingRoute).should.be(true);
			});

			afterEach({
				app?.close();
			});
		});
	}
}
