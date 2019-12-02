package helm;

import sys.FileSystem as FS;

using StringTools;

class FileSystem
{

	/**
	 * The separator character to use between folders (/ vs \)
	 */
	static public var SEPARATOR(get, never):String;
	static private inline function get_SEPARATOR():String
	{
		return isWindows ? "\\" : "/";
	}

	/**
	 * The home directory of user (os specific)
	 */
	static public var homeDir(get, never):Path;
	static private function get_homeDir():Path
	{
		return isWindows ? Sys.getEnv("HOMEDRIVE") + Sys.getEnv("HOMEPATH") : Sys.getEnv("HOME");
	}

	static private var isWindows(get, never):Bool;
	static private inline function get_isWindows():Bool
	{
		return (Sys.systemName() == "Windows");
	}

	/**
	 * True if directory exists and is a directory
	 */
	static public function exists(path:Path):Bool
	{
		return FS.exists(path) && FS.isDirectory(path);
	}

	static public function rename(oldPath:Path, newPath:Path):Void
	{
		FS.rename(oldPath, newPath);
	}

	/**
	 * Create a directory if it doesn't already exist
	 * @param path the directory's path
	 * @return if the directory is successfully created
	 */
	static public function create(path:Path):Bool
	{
		if (!FileSystem.exists(path))
		{
			try
			{
				FS.createDirectory(path);
			}
			catch (e:Dynamic)
			{
				return false;
			}
			return true;
		}
		return false;
	}

	/**
	 * Recursively delete directory contents and the directory itself
	 * @param path the directory's path
	 * @return if the directory is successfully deleted
	 */
	static public function delete(path:Path, recursive:Bool=true):Bool
	{
		if (FileSystem.exists(path))
		{
			if (!path.endsWith(FileSystem.SEPARATOR))
			{
				path = path + FileSystem.SEPARATOR;
			}

			if (recursive)
			{
				for (item in FS.readDirectory(path))
				{
					var newPath = path.join(item);
					if (FS.isDirectory(newPath))
					{
						FileSystem.delete(newPath, recursive);
					}
					else
					{
						FS.deleteFile(newPath);
					}
				}
			}
			FS.deleteDirectory(path);
			return true;
		}
		return false;
	}

	static public function readDirectory(path:Path):Array<String>
	{
		return FS.exists(path) ? FS.readDirectory(path) : [];
	}

	/**
	 * Create a temporary folder
	 * @return A Directory object with the created temp path
	 */
	static public function createTemporary():Path
	{
		var tmp = Sys.getEnv("TEMP");
		if (tmp == null) tmp = "/tmp";
		var path:String;
		do {
			var crypt = haxe.crypto.Md5.encode(Std.string(Date.now())).substr(0, 10);
			path = tmp + SEPARATOR + "helm_" + crypt + SEPARATOR;
		} while (FS.exists(path));
		return path;
	}

}
