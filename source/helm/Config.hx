package helm;

import sys.FileSystem;
import sys.io.File;

class Config
{

	static public var useGlobal:Bool = false;
	static public var haxelibCompatible:Bool = true;

	@:isVar static public var globalPath(get, null):Path;
	static private function get_globalPath():Path
	{
		if (globalPath == null) load();
		return globalPath;
	}

	static public var cachePath(get, never):Path;
	static private inline function get_cachePath():Path
	{
		return globalPath.join("cache");
	}

	static public var helmPath(get, never):Path;
	static private inline function get_helmPath():Path
	{
		// TODO: verify that this actually exists, assumes it is installed
		return globalPath.join("helm");
	}

	static private function load()
	{
		var home = Directory.homeDir;
		var config = {
			"haxelib_compat": haxelibCompatible,
			"repo_path": "",
			"install": useGlobal
		};

		try {
			var path = home.join(".helmconfig");
			if (sys.FileSystem.exists(path))
			{
				config = haxe.Json.parse(sys.io.File.getContent(path));
			}
			else if (sys.FileSystem.exists("/etc/helm"))
			{
				config = haxe.Json.parse(sys.io.File.getContent("/etc/helm"));
			}
		} catch (e:Dynamic) {
			throw "Could not find or parse helm config (expected ~/.helmconfig or /etc/helm)";
		}

		useGlobal = config.install;
		haxelibCompatible = config.haxelib_compat;
		if (haxelibCompatible)
		{
			#if haxelib
			globalPath = org.haxe.lib.Haxelib.path;
			#end
		}
		else
		{
			globalPath = config.repo_path;
		}
	}

}
