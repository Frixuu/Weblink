package weblink;

import haxe.io.Bytes;
import weblink._internal.AsciiTools;

enum abstract HeaderKey(String) to String {
	public var Accept = "accept";
	public var AcceptCH = "accept-ch";
	public var AcceptCharset = "accept-charset";
	public var AcceptDatetime = "accept-datetime";
	public var AcceptEncoding = "accept-encoding";
	public var AcceptLanguage = "accept-language";
	public var AcceptPatch = "accept-patch";
	public var AcceptRanges = "accept-ranges";
	public var AccessControlAllowCredentials = "access-control-allow-credentials";
	public var AccessControlAllowHeaders = "access-control-allow-headers";
	public var AccessControlAllowMethods = "access-control-allow-methods";
	public var AccessControlAllowOrigin = "access-control-allow-origin";
	public var AccessControlExposeHeaders = "access-control-expose-headers";
	public var AccessControlRequestHeaders = "access-control-request-headers";
	public var AccessControlRequestMethod = "access-control-request-method";
	public var Age = "age";
	public var AIM = "aim";
	public var Allow = "allow";
	public var AltSvc = "alt-svc";
	public var Authorization = "authorization";
	public var CacheControl = "cache-control";
	public var Connection = "connection";
	public var ContentDisposition = "content-disposition";
	public var ContentEncoding = "content-encoding";
	public var ContentLanguage = "content-language";
	public var ContentLength = "content-length";
	public var ContentLocation = "content-location";
	public var ContentMD5 = "content-md5";
	public var ContentRange = "content-range";
	public var ContentSecurityPolicy = "content-security-policy";
	public var ContentType = "content-type";
	public var Cookie = "cookie";
	public var Date = "date";
	public var DeltaBase = "delta-base";
	public var DNT = "dnt";
	public var ETag = "etag";
	public var Expect = "expect";
	public var Expires = "expires";
	public var Forwarded = "forwarded";
	public var From = "from";
	public var FrontEndHttps = "front-end-https";
	public var Host = "host";
	public var HTTP2Settings = "http2-settings";
	public var IfMatch = "if-match";
	public var IfModifiedSince = "if-modified-since";
	public var IfNoneMatch = "if-none-match";
	public var IfRange = "if-range";
	public var IfUnmodifiedSince = "if-unmodified-since";
	public var IM = "im";
	public var LastModified = "last-modified";
	public var Link = "link";
	public var Location = "location";
	public var MaxForwards = "max-forwards";
	public var NEL = "nel";
	public var Origin = "origin";
	public var Pragma = "pragma";
	public var Prefer = "prefer";
	public var PreferenceApplied = "preference-applied";
	public var ProxyAuthenticate = "proxy-authenticate";
	public var ProxyAuthorization = "proxy-authorization";
	public var PublicKeyPins = "public-key-pins";
	public var Range = "range";
	public var Referer = "referer";
	public var Refresh = "refresh";
	public var ReportTo = "report-to";
	public var RetryAfter = "retry-after";
	public var SaveData = "save-data";
	public var SecFetchDest = "sec-fetch-dest";
	public var SecFetchMode = "sec-fetch-mode";
	public var SecFetchSite = "sec-fetch-site";
	public var SecFetchUser = "sec-fetch-user";
	public var SecGPC = "sec-gpc";
	public var Server = "server";
	public var SetCookie = "set-cookie";
	public var StrictTransportSecurity = "strict-transport-security";
	public var TE = "te";
	public var Tk = "tk";
	public var Trailer = "trailer";
	public var TransferEncoding = "transfer-encoding";
	public var Upgrade = "upgrade";
	public var UpgradeInsecureRequests = "upgrade-insecure-requests";
	public var UserAgent = "user-agent";
	public var Vary = "vary";
	public var Via = "via";
	public var Warning = "warning";
	public var WWWAuthenticate = "www-authenticate";
	public var XContentTypeOptions = "x-content-type-options";
	public var XForwardedFor = "x-forwarded-for";
	public var XForwardedHost = "x-forwarded-host";
	public var XForwardedProto = "x-forwarded-proto";
	public var XFrameOptions = "x-frame-options";
	public var XHttpMethodOverride = "x-http-method-override";
	public var XPoweredBy = "x-powered-by";
	public var XRedirectBy = "x-redirect-by";
	public var XRequestedWith = "x-requested-with";
	public var XRequestID = "x-request-id";
	public var XUACompatible = "x-ua-compatible";
	public var XXSSProtection = "x-xss-protection";

	/**
		Tries to normalize a string into a header field name.

		Returns null if the string is not a valid header key.
	**/
	public static function tryNormalizeString(s:String):Null<HeaderKey> {
		final len = s.length;
		final bytes = Bytes.alloc(len);
		for (i in 0...len) {
			final char = StringTools.fastCodeAt(s, i);
			if (char > 127) {
				return null; // Not US-ASCII. Could be ISO-8859-1, but we don't care enough
			}
			if (!AsciiTools.isCharAllowedInToken(char)) {
				return null; // Character is not printable or a separator
			}
			if (char >= 65 && char <= 90) {
				bytes.set(i, char + 32); // Convert to lowercase
			} else {
				bytes.set(i, char);
			}
		}

		return cast bytes.toString();
	}

	@:from
	public static inline function normalizeOrThrow(s:String):HeaderKey {
		final key = HeaderKey.tryNormalizeString(s);
		if (key == null) {
			throw '"$s" is an invalid header key (contains non-printable or non-ASCII characters)';
		}
		return key;
	}
}
