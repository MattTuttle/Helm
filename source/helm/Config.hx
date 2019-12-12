package helm;

class Config {
	static public var useGlobal:Bool = false;

	static public var globalPath(get, never):Path;

	static private function get_globalPath():Path {
		return FileSystem.homeDir.join(".helm");
	}

	static public var cachePath(get, never):Path;

	static private inline function get_cachePath():Path {
		return globalPath.join("cache");
	}

	static public var helmPath(get, never):Path;

	static private inline function get_helmPath():Path {
		// TODO: verify that this actually exists, assumes it is installed
		return globalPath;
	}
}
