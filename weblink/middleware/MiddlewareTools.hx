package weblink.middleware;

/**
	Wraps the provided handler with the middlewares in the chain,
	so that we can avoid middleware lookup at runtime.
**/
function flatten(chain:Array<Middleware>, handler:Handler):Handler {
	var i = chain.length - 1;
	while (i >= 0) {
		handler = chain[i](handler);
		i -= 1;
	}
	return handler;
}
