package;

import buddy.Buddy;

class TestMain implements Buddy<[
	security.BCryptSuite,
	security.CredentialsProviderSuite,
	security.JwksSuite,
	security.JwtSuite,
	security.JwtSigningSuite,
	CompressionSuite,
	CookieSuite,
	MethodSuite,
	MiddlewareSuite,
	PostDataSuite,
	RadixTreeSuite,
	ReflectionSuite,
]> {}
