package weblink;

import haxe.http.HttpMethod;
import weblink.Handler;
import weblink._internal.Server;
import weblink._internal.ds.RadixTree;
import weblink.middleware.Middleware;
import weblink.middleware.MiddlewareTools.flatten;
import weblink.routing.HttpRouter;
import weblink.routing.IHttpRouter;
import weblink.routing.SubRouter;
import weblink.security.CredentialsProvider;
import weblink.security.Jwks;
import weblink.security.OAuth.OAuthEndpoints;

using haxe.io.Path;

@:using(weblink.routing.HttpRoutingTools)
class Weblink implements IHttpRouter<Weblink> {
	public var server:Null<Server>;

	private final httpRouter:HttpRouter;

	/**
		Default anonymous function defining the behavior should a requested route not exist.
		Suggested that application implementers use set_pathNotFound() to define custom 404 status behavior/pages
	**/
	public var pathNotFound(null, set):Handler = function(request:Request, response:Response):Void {
		response.status = 404;
		response.send("Error 404, Route Not found.");
	}

	var _serve:Bool = false;
	var _path:String;
	var _dir:String;
	var _cors:String = "*";

	public function new() {
		this.httpRouter = new HttpRouter();
	}

	/**
		Adds middleware to new routes. Does not affect already registered routes.

		Middleware is a function that intercepts incoming requests and takes action on them.
		Middleware can be used for logging, authentication and many more.
	**/
	public inline function use(middleware:Middleware):Weblink {
		this.httpRouter.use(middleware);
		return this;
	}

	/**
		Registers an HTTP handler for the given path and method.
		@param method The HTTP verb to register the handler to, e.g. `Get`.
		@param path Path to the resource, e.g. `"/article/:slug"`.
		@param handler The callback to respond to the request with.
	**/
	public inline function handleHttp(method:HttpMethod, path:String, handler:Handler):Weblink {
		this.httpRouter.handleHttp(method, path, handler);
		return this;
	}

	/**
		Registers a router subgroup. It can its own middleware.
		@param path The path prefix to the subgroup.
		@param configure The function that configures the subgroup.
	**/
	public function group(path:String, configure:(router:SubRouter) -> Void):Weblink {
		this.httpRouter.group(path, configure);
		return this;
	}

	public function listen(port:Int, blocking:Bool = true) {
		this.pathNotFound = flatten(this.httpRouter.httpMiddlewareChain, this.pathNotFound);
		server = new Server(port, this);
		server.update(blocking);
	}

	public function serve(path:String = "", dir:String = "", cors:String = "*") {
		_cors = cors;
		_path = path;
		_dir = dir;
		_serve = true;
	}

	public function close() {
		server.close();
	}

	/**
	 * Add JSON Web Key Sets HTTP endpoint
	 */
	public function jwks(jwks:Jwks, ?path = "/jwks"):Weblink {
		this.get(path, (request:Request, response:Response) -> jwks.jwksGetEndpoint(request, response));
		this.post(path, (request:Request, response:Response) -> jwks.jwksPostEndpoint(request, response));
		return this;
	}

	public function users(credentialsProvider:CredentialsProvider, ?path = "/users"):Weblink {
		this.get(path, credentialsProvider.getUsersEndpoint);
		this.post(path, credentialsProvider.postUsersEndpoint);
		return this;
	}

	public function oauth2(secret_key:String, credentialsProvider:CredentialsProvider, ?path = "/token"):Weblink {
		var oauth2 = new OAuthEndpoints(path, secret_key, credentialsProvider);
		this.post(path, oauth2.login_for_access_token);
		return this;
	}

	private inline function _serveEvent(request:Request, response:Response):Bool {
		if (request.path.charAt(0) == "/")
			request.path = request.basePath.substr(1);
		var ext = request.path.extension();
		var mime = weblink._internal.Mime.types.get(ext);
		response.headers = new List<Header>();
		if (_cors.length > 0)
			response.headers.add({key: "Access-Control-Allow-Origin", value: _cors});
		response.contentType = mime == null ? "text/plain" : mime;
		var path = Path.join([_dir, request.basePath.substr(_path.length)]).normalize();
		if (path == "")
			path = ".";
		if (sys.FileSystem.exists(path)) {
			if (sys.FileSystem.isDirectory(path)) {
				response.contentType = "text/html";
				path = Path.join([path, "index.html"]);
				if (sys.FileSystem.exists(path)) {
					response.sendBytes(sys.io.File.getBytes(path));
					return true;
				}
				trace('file not found $path');
				return false;
			} else {
				response.sendBytes(sys.io.File.getBytes(path));
				return true;
			}
		} else {
			trace('file/folder not found $path');
			return false;
		}
	}

	public function set_pathNotFound(value:Handler):Handler {
		if (this.server != null) {
			throw "cannot change fallback handler at runtime";
		}

		this.pathNotFound = value;
		return this.pathNotFound;
	}
}
