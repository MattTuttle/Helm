import sys.FileSystem;
import sys.io.File;

using StringTools;

class Config
{

	static public var globalPath:String;

	static public var cachePath(get, never):String;
	static private function get_cachePath():String
	{
		return globalPath + "cache/";
	}

	static public function load():Void
	{
		globalPath = Sys.getEnv("HAXELIB_PATH");
		if (globalPath == null)
		{
			var isWindows = (Sys.systemName() == "Windows");
			var home = isWindows ? Sys.getEnv("HOMEDRIVE") + Sys.getEnv("HOMEPATH") : Sys.getEnv("HOME");
			if (FileSystem.exists(home + "/.haxelib"))
			{
				globalPath = File.getContent(home + "/.haxelib");
			}
			else if (FileSystem.exists("/etc/haxelib"))
			{
				globalPath = File.getContent("/etc/haxelib");
			}
			else
			{
				globalPath = "/usr/local/lib/haxe/";
			}
		}

		// make sure the path ends with a slash
		if (!globalPath.endsWith("/"))
		{
			globalPath += "/";
		}

		if (!(FileSystem.exists(globalPath) && FileSystem.isDirectory(globalPath)))
		{
			throw "Invalid package directory " + globalPath;
		}
	}

}
