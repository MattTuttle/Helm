import sys.FileSystem;
import sys.io.File;

using StringTools;

class Config
{

	static public var useGlobal:Bool = false;
	static public var globalPath:String;

	static public var cachePath(get, never):String;
	static private function get_cachePath():String
	{
		return globalPath + "cache/";
	}

	static public var helmPath(get, never):String;
	static private function get_helmPath():String
	{
		// TODO: verify that this actually exists, assumes it is installed
		return globalPath + "helm/";
	}

	static public function load():Void
	{
		globalPath = Sys.getEnv("HAXELIB_PATH");
		if (globalPath == null)
		{
			var isWindows = (Sys.systemName() == "Windows");
			Directory.SEPARATOR = isWindows ? "\\" : "/";
			var home = isWindows ? Sys.getEnv("HOMEDRIVE") + Sys.getEnv("HOMEPATH") : Sys.getEnv("HOME");
			if (FileSystem.exists(home + Directory.SEPARATOR + ".haxelib"))
			{
				globalPath = File.getContent(home + Directory.SEPARATOR + ".haxelib");
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
		if (!globalPath.endsWith(Directory.SEPARATOR))
		{
			globalPath += Directory.SEPARATOR;
		}

		if (!(FileSystem.exists(globalPath) && FileSystem.isDirectory(globalPath)))
		{
			throw "Invalid package directory " + globalPath;
		}
	}

}
