package weblink._internal.libuv;

private typedef RawLoop = hl.Abstract<"uv_loop">;

/**
	Event loop.
**/
@:notNull
@:nullSafety(StrictThreaded)
abstract UvLoop(RawLoop) from RawLoop to RawLoop {
	/**
		Gets the default libuv loop.

		Unlike `hl.uv.Loop`, does NOT register a MainLoop event.
	**/
	public static function defaultOrThrow():UvLoop {
		final loop:Null<UvLoop> = cast @:privateAccess hl.uv.Loop.default_loop();
		if (loop != null) {
			return loop;
		}

		// Hashlink bindings do not expose libuv error codes for this operation
		throw new UvException("Could not get/allocate default libuv event loop");
	}

	/**
		Runs this event loop. It will act differently based on the chosen mode.
		@param mode See `UvLoop.RunMode`.
	**/
	public inline function run(mode:RunMode) {
		final loop:hl.uv.Loop = cast this;
		loop.run(cast mode);
	}

	/**
		Stops this event loop, causing `run()` to return as soon as the next iteration.
	**/
	public inline function stop() {
		final loop:hl.uv.Loop = cast this;
		loop.stop();
	}
}

enum abstract RunMode(Int) {
	/**
		The loop will run continuously until explicitly stopped
		or it no longer has any active resources.
	**/
	public var Default = 0;

	/**
		Polls for I/O just once.
		If there are no pending callbacks, blocks until there is at least one.
	**/
	public var Once = 1;

	/**
		Polls for I/O just once.
		Unlike the `Once` mode, it does not block when there are no active callbacks.
	**/
	public var NoWait = 2;
}
