package weblink.routing;

import haxe.http.HttpMethod;
import weblink.Handler;
import weblink._internal.ds.RadixTree;
import weblink.middleware.Middleware;
import weblink.middleware.MiddlewareTools.flatten;

@:nullSafety(StrictThreaded)
class HttpRouter implements IHttpRouter {
	/**
		The route tree for HTTP handlers.
	**/
	public final httpRouteTree:RadixTree<Handler>;

	/** 
		The middleware chain for HTTP handlers,
		stored in the insertion order (reverse execution order).
	**/
	public final httpMiddlewareChain:Array<Middleware>;

	public function new(?middlewareChain:Array<Middleware>) {
		this.httpRouteTree = new RadixTree();
		this.httpMiddlewareChain = middlewareChain != null ? middlewareChain : [];
	}

	/**
		Adds middleware to new HTTP routes. Does not affect already registered routes.

		`Middleware` is a function that intercepts incoming requests and takes action on them.
		Middleware can be used for logging, authentication and many more.
		@param middleware The middleware to apply to the handler.
	**/
	public inline function use(middleware:Middleware):HttpRouter {
		this.httpMiddlewareChain.push(middleware);
		return this;
	}

	/**
		Registers an HTTP handler for the given path and method.
		@param method The HTTP verb to register the handler to, e.g. `Get`.
		@param path Path to the resource, e.g. `"/article/:slug"`.
		@param handler The callback to respond to the request with.
	**/
	public inline function handleHttp(method:HttpMethod, path:String, handler:Handler):HttpRouter {
		this.httpRouteTree.put(path, method, flatten(this.httpMiddlewareChain, handler));
		return this;
	}

	/**
		Registers a router subgroup. It can its own middleware.
		@param path The path prefix to the subgroup.
		@param configure The function that configures the subgroup.
	**/
	public function group(path:String, configure:(group:IHttpRouter) -> Void):HttpRouter {
		final subrouter = new SubRouter();
		configure(subrouter);
		for (registration in @:privateAccess subrouter.registeredHandlers) {
			this.httpRouteTree.put(path + registration.path, registration.method, flatten(this.httpMiddlewareChain, registration.handler));
		}
		return this;
	}
}
