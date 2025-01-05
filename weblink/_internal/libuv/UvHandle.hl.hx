package weblink._internal.libuv;

private typedef RawHandle = hl.Abstract<"uv_handle">;

/**
	Base libuv handle.
**/
@:notNull
@:nullSafety(StrictThreaded)
abstract UvHandle(RawHandle) from RawHandle to RawHandle {
	/**
		Requests this resource to be closed.
		Note: This call is non-blocking.
		@param callback Optional callback that is executed when the handle is closed.
	**/
	public inline function closeAsync(?callback:() -> Void) {
		Uv.close(cast this, callback);
	}
}
