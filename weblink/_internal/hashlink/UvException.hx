package weblink._internal.hashlink;

import haxe.Exception;

/**
	Base exception for errors that originate from libuv.
**/
@:nullSafety(StrictThreaded)
class UvException extends Exception {
	public function new(message:String) {
		super(message);
	}
}
