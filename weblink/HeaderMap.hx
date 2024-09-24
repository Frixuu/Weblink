package weblink;

/**
	A specialized map with case-insensitive keys and multiple values.

	Note: This implementation is NOT thread-safe.
**/
class HeaderMap {
	private var inner:Map<HeaderKey, Array<HeaderValue>>;

	public function new() {
		this.inner = [];
	}

	/**
		Returns all values associated with the key, if there are any.
	**/
	public function getAll(key:HeaderKey):Null<Array<HeaderValue>> {
		return this.inner.get(key);
	}

	/**
		Returns a value associated with the key, if there is one.

		If multiple values are associated with the key, the first one is returned.
		Use `getAll()` to get all values.
	**/
	public function get(key:HeaderKey):Null<HeaderValue> {
		final values = this.getAll(key);
		return values != null && values.length > 0 ? values[0] : null;
	}

	/**
		Gets an array of values for a given key.
		If the mapping for the key does not exist, it will be created.
	**/
	private function getOrCreateValuesArray(key:HeaderKey):Array<HeaderValue> {
		final existingValues = this.getAll(key);
		if (existingValues != null) {
			return existingValues;
		}

		final newValues = [];
		this.inner.set(key, newValues);
		return newValues;
	}

	/**
		Adds a value to the list of values for the given key.
	**/
	public function add(key:HeaderKey, value:HeaderValue) {
		final values = this.getOrCreateValuesArray(key);
		values.push(value);
	}

	/**
		Sets the value as the only value for the given key.
	**/
	public function set(key:HeaderKey, value:HeaderValue) {
		final values = this.getOrCreateValuesArray(key);
		values.resize(0);
		values.push(value);
	}

	/**
		Checks if the given key exists in the map.
	**/
	public function exists(key:HeaderKey):Bool {
		final values = this.getAll(key);
		return values != null && values.length > 0;
	}

	public function remove(key:HeaderKey):Bool {
		return this.inner.remove(key);
	}

	public function keys():Iterator<HeaderKey> {
		return this.inner.keys();
	}

	public function iterator():Iterator<Array<HeaderValue>> {
		return this.inner.iterator();
	}

	public function keyValueIterator():KeyValueIterator<HeaderKey, Array<HeaderValue>> {
		return this.inner.keyValueIterator();
	}

	public function toString():String {
		return this.inner.toString();
	}

	/**
		Clears the map, removing all key-value pairs.
	**/
	public function clear() {
		this.inner.clear();
	}

	/**
		Copies the headers from a `Map<String, String>` source, like `haxe.Http#responseHeaders`.

		Useful when wanting to compare headers in an case-insensitive way.
	**/
	public static function fromCaseSensitiveSource(headers:Map<String, String>):HeaderMap {
		final map = new HeaderMap();
		for (key => value in headers) {
			final headerKey = HeaderKey.tryNormalizeString(key);
			if (headerKey != null) {
				map.set(headerKey, value);
			}
		}
		return map;
	}
}
