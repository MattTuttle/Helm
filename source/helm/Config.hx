package helm;

import sys.FileSystem;
import sys.io.File;

using StringTools;

class Config
{

	static public var useGlobal:Bool = false;

	static public var isWindows(get, never):Bool;
	static private inline function get_isWindows():Bool
	{
		return (Sys.systemName() == "Windows");
	}

	@:isVar static public var globalPath(get, null):String;
	static private function get_globalPath():String
	{
		if (globalPath == null)
		{
			var path = Sys.getEnv("HAXELIB_PATH");
			if (path == null)
			{
				var home = isWindows ? Sys.getEnv("HOMEDRIVE") + Sys.getEnv("HOMEPATH") : Sys.getEnv("HOME");
				if (FileSystem.exists(home + Directory.SEPARATOR + ".haxelib"))
				{
					path = File.getContent(home + Directory.SEPARATOR + ".haxelib");
				}
				else if (FileSystem.exists("/etc/haxelib"))
				{
					path = File.getContent("/etc/haxelib");
				}
				else
				{
					path = "/usr/local/lib/haxe/";
				}
			}

			// make sure the path ends with a slash
			if (!path.endsWith(Directory.SEPARATOR))
			{
				path += Directory.SEPARATOR;
			}

			if (!(FileSystem.exists(path) && FileSystem.isDirectory(path)))
			{
				throw "Invalid package directory " + path;
			}
			globalPath = path;
		}

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

}
