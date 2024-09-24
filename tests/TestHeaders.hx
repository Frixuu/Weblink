import weblink.HeaderKey;

using TestingTools;

class TestHeaders {
	public static function main() {
		trace("Starting Headers Test");

		// Implicit key conversions (should be allowed to compile)
		{
			final key:HeaderKey = "Content-Encoding";
			if (key != "content-encoding") {
				throw "the header was not normalized correctly";
			}
		}

		// Explicit key conversions
		{
			final key = HeaderKey.tryNormalizeString("X-Custom-Header");
			if (key == null) {
				throw "did not recognized X-Custom-Header as a valid header key";
			}

			if (key != "x-custom-header") {
				throw "the header was not normalized correctly";
			}
		}
		{
			final key = HeaderKey.tryNormalizeString("hello world");
			if (key != null) {
				throw "incorrectly recognized \"hello world\" as a valid header key";
			}
		}

		trace("done");
	}
}
