package helm;

import sys.FileSystem;
import sys.io.File;

class Config
{

	static public var useGlobal:Bool = true;
	static public var haxelibCompatible:Bool = true;

	@:isVar static public var globalPath(get, null):String;
	static private function get_globalPath():String
	{
		if (globalPath == null) load();
		return globalPath;
	}

	static public var cachePath(get, never):String;
	static private inline function get_cachePath():String
	{
		return globalPath + "cache/";
	}

	static public var helmPath(get, never):String;
	static private inline function get_helmPath():String
	{
		// TODO: verify that this actually exists, assumes it is installed
		return globalPath + "helm/";
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
			if (sys.FileSystem.exists(home + Directory.SEPARATOR + ".hxpmconfig"))
			{
				config = haxe.Json.parse(sys.io.File.getContent(home + Directory.SEPARATOR + ".hxpmconfig"));
			}
			else if (sys.FileSystem.exists("/etc/hxpm"))
			{
				config = haxe.Json.parse(sys.io.File.getContent("/etc/hxpm"));
			}
		} catch (e:Dynamic) {
			throw "Could not find or parse hxpm config (expected ~/.hxpmconfig or /etc/hxpm)";
		}

		useGlobal = config.install;
		haxelibCompatible = config.haxelib_compat;
		if (haxelibCompatible)
		{
			globalPath = org.haxe.lib.Haxelib.path;
		}
		else
		{
			globalPath = config.repo_path;
		}
	}

}
