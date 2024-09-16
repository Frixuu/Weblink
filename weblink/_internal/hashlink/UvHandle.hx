package weblink._internal.hashlink;

import hl.uv.Handle;

private typedef RawHandle = hl.Abstract<"uv_handle">;

abstract UvHandle(RawHandle) from RawHandle to RawHandle {
	public inline function close(?callback:() -> Void) {
		if (this == null)
			return;
		@:privateAccess Handle.close_handle(this, callback);
		// this = null;
	}
}
