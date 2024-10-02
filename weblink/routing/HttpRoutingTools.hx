package weblink.routing;

import haxe.http.HttpMethod;
import haxe.macro.Expr.FunctionArg;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Field;
#else
import weblink.middleware.Middleware;
#end

/**
	Extensions for registering HTTP handlers for specific HTTP methods.
**/
@:nullSafety(StrictThreaded)
#if !macro
@:build(weblink.routing.HttpRoutingTools.buildHttpMethodExtensions())
#end
final class HttpRoutingTools {
	#if macro
	private static macro function buildHttpMethodExtensions():Array<Field> {
		final pos = Context.currentPos();
		final fields:Array<Field> = Context.getBuildFields();
		final methods:Array<HttpMethod> = [Get, Post, Head, Put, Delete, Trace, Options, Connect, Patch];
		for (method in methods) {
			final doc = {
				final s = new StringBuf();
				s.add("Registers an HTTP ");
				s.add((method : String).toUpperCase());
				s.add(" handler for the given path.\n");
				s.add("@param path Path to the resource, e.g. `\"/article/:slug\"`.\n");
				s.add("@param handler The callback to respond to the request with.\n");
				if (method == Get) {
					s.add("@param middleware (Optional) The middleware to apply to the handler. ");
					s.add("This param is deprecated; call `middleware(handler)` instead.\n");
				}
				s.toString();
			};

			final args:Array<FunctionArg> = [];
			args.push({name: "router", type: macro :T});
			args.push({name: "path", type: macro :String});
			args.push({name: "handler", type: macro :weblink.Handler});
			if (method == Get) {
				args.push({name: "middleware", type: macro :weblink.middleware.Middleware, opt: true});
			}

			final expr = if (method != Get) {
				macro {
					router.handleHttp($v{method}, path, handler);
					return router;
				}
			} else {
				macro {
					router.handleHttp($v{method}, path, middleware != null ? middleware(handler) : handler);
					return router;
				}
			};

			fields.push({
				doc: doc,
				meta: [],
				access: [APublic, AStatic, AInline],
				name: (method : String).toLowerCase(),
				pos: pos,
				kind: FFun({
					params: [{name: "T", constraints: [macro :weblink.routing.IHttpRouter]}],
					ret: macro :T,
					args: args,
					expr: expr,
				}),
			});
		}
		return fields;
	}
	#end
}
