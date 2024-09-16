package;

import buddy.Buddy;

class TestMain implements Buddy<[
	MiddlewareSuite,
	security.BCryptSuite,
	security.JwksSuite,
	security.JwtSigningSuite,
]> {}
