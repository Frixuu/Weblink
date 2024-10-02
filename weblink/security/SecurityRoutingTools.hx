package weblink.security;

import weblink.routing.IHttpRouter;
import weblink.security.OAuth.OAuthEndpoints;

using weblink.routing.HttpRoutingTools;

@:nullSafety(StrictThreaded)
final class SecurityRoutingTools {
	/**
	 * Add JSON Web Key Sets HTTP endpoint
	 */
	public static inline function jwks<T:IHttpRouter<T>>(router:T, jwks:Jwks, path = "/jwks"):T {
		router.get(path, (request:Request, response:Response) -> jwks.jwksGetEndpoint(request, response));
		router.post(path, (request:Request, response:Response) -> jwks.jwksPostEndpoint(request, response));
		return router;
	}

	public static inline function users<T:IHttpRouter<T>>(router:T, credentialsProvider:CredentialsProvider, path = "/users"):T {
		router.get(path, credentialsProvider.getUsersEndpoint);
		router.post(path, credentialsProvider.postUsersEndpoint);
		return router;
	}

	public static inline function oauth2<T:IHttpRouter<T>>(router:T, secret_key:String, credentialsProvider:CredentialsProvider, path = "/token"):T {
		final oauth2 = new OAuthEndpoints(path, secret_key, credentialsProvider);
		router.post(path, oauth2.login_for_access_token);
		return router;
	}
}
