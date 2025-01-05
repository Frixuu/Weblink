package weblink._internal.libuv;

import haxe.io.Bytes;

/**
	A libuv handle to a "duplex communication channel".
**/
@:forward
@:notNull
@:nullSafety(StrictThreaded)
abstract UvStreamHandle(UvHandle) to UvHandle {
	/**
		Starts listening for incoming connections.
		@param backlog The maximum number of queued connections.
		@param callback A callback that is executed on an incoming connection.
	**/
	public function listenOrThrow(backlog:Int, callback:() -> Void) {
		final success = Uv.listen(cast this, backlog, callback);
		if (!success) {
			// Hashlink bindings do not expose libuv error codes for this operation
			throw new UvException("Could not start listening for incoming connections");
		}
	}

	/**
		Writes binary data to this stream.
		@param bytes Bytes to write.
	**/
	public function writeBytesOrThrow(bytes:haxe.io.Bytes) {
		final data = (@:privateAccess bytes.b).offset(0);
		final success = Uv.write(cast this, data, bytes.length, cast null);
		if (!success) {
			// Hashlink bindings do not expose libuv error codes for this operation
			throw new UvException("Failed to write data to a libuv stream");
		}
	}

	/**
		Starts reading data from this stream.
		The callback will be made many times until there is no more data to read.
	**/
	public function readStartOrThrow(callback:(data:ReadData) -> Void) {
		final success = Uv.readStart(cast this, (buffer, nRead) -> {
			if (nRead > 0) {
				// Data is available
				callback(Data(buffer.toBytes(nRead)));
			} else if (nRead == 0) {
				// Read would block or there is no data available, ignore
			} else {
				callback(Error(nRead));
			}
		});

		if (!success) {
			// Hashlink bindings do not expose libuv error codes for this operation
			throw new UvException("Could not start reading from a libuv stream");
		}
	}
}

enum ReadData {
	Data(bytes:Bytes);
	Error(code:UvError);
}
