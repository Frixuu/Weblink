package weblink.routing;

import haxe.http.HttpMethod;

/**
	A router that can register HTTP request handlers.
	@param <T> The implementing class itself.

**/
@:using(weblink.routing.HttpRoutingTools)
interface IHttpRouter<T:IHttpRouter<T>> {
	/**
		Registers an HTTP handler for the given path and method.
		@param method The HTTP verb to register the handler to, e.g. `Get`.
		@param path Path to the resource, e.g. `"/article/:slug"`.
		@param handler The callback to respond to the request with.
	**/
	public function handleHttp(method:HttpMethod, path:String, handler:Handler):T;
}
