package weblink.routing;

import haxe.http.HttpMethod;
import weblink.middleware.Middleware;

/**
	A router that can register HTTP request handlers.
	@param <T> The implementing class itself.

**/
@:using(weblink.routing.HttpRoutingTools)
interface IHttpRouter<T:IHttpRouter<T>> {
	/**
		Adds middleware to new HTTP routes. Does not affect already registered routes.

		`Middleware` is a function that intercepts incoming requests and takes action on them.
		Middleware can be used for logging, authentication and many more.
		@param middleware The middleware to apply to the handler.
	**/
	public function use(middleware:Middleware):T;

	/**
		Registers an HTTP handler for the given path and method.
		@param method The HTTP verb to register the handler to, e.g. `Get`.
		@param path Path to the resource, e.g. `"/article/:slug"`.
		@param handler The callback to respond to the request with.
	**/
	public function handleHttp(method:HttpMethod, path:String, handler:Handler):T;

	/**
		Registers a router subgroup. It can its own middleware.
		@param path The path prefix to the subgroup.
		@param configure The function that configures the subgroup.
	**/
	public function group(path:String, configure:(group:SubRouter) -> Void):T;
}
