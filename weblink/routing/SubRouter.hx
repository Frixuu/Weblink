package weblink.routing;

import haxe.http.HttpMethod;
import weblink.Handler;
import weblink._internal.ds.RadixTree;
import weblink.middleware.Middleware;
import weblink.middleware.MiddlewareTools.flatten;

@:nullSafety(StrictThreaded)
class SubRouter implements IHttpRouter<SubRouter> {
	/**
		Handlers registered in this subrouter.
	**/
	private final registeredHandlers:Array<RegisteredHandler>;

	/** 
		The middleware chain for HTTP handlers,
		stored in the insertion order (reverse execution order).
	**/
	private final httpMiddlewareChain:Array<Middleware>;

	public function new() {
		this.registeredHandlers = [];
		this.httpMiddlewareChain = [];
	}

	/**
		Adds middleware to new HTTP routes. Does not affect already registered routes.

		`Middleware` is a function that intercepts incoming requests and takes action on them.
		Middleware can be used for logging, authentication and many more.
		@param middleware The middleware to apply to the handler.
	**/
	public inline function use(middleware:Middleware):SubRouter {
		this.httpMiddlewareChain.push(middleware);
		return this;
	}

	/**
		Registers an HTTP handler for the given path and method.
		@param method The HTTP verb to register the handler to, e.g. `Get`.
		@param path Path to the resource, e.g. `"/article/:slug"`.
		@param handler The callback to respond to the request with.
	**/
	public inline function handleHttp(method:HttpMethod, path:String, handler:Handler):SubRouter {
		this.registeredHandlers.push({path: path, method: method, handler: flatten(this.httpMiddlewareChain, handler)});
		return this;
	}

	/**
		Registers a router subgroup. It can its own middleware.
		@param path The path prefix to the subgroup.
		@param configure The function that configures the subgroup.
	**/
	public function group(path:String, configure:(group:SubRouter) -> Void):SubRouter {
		final subrouter = new SubRouter();
		configure(subrouter);
		for (registration in subrouter.registeredHandlers) {
			this.registeredHandlers.push({
				path: path + registration.path,
				method: registration.method,
				handler: flatten(this.httpMiddlewareChain, registration.handler),
			});
		}
		return this;
	}
}

@:structInit
private final class RegisteredHandler {
	public var path:String;
	public var method:HttpMethod;
	public var handler:Handler;
}
