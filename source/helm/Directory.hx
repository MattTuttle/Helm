package helm;

import sys.FileSystem;

using StringTools;

class Directory
{

	/**
	 * The directory path
	 */
	public var path(default, null):String;

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
	static public var homeDir(get, never):String;
	static private function get_homeDir():String
	{
		return isWindows ? Sys.getEnv("HOMEDRIVE") + Sys.getEnv("HOMEPATH") : Sys.getEnv("HOME");
	}

	static private var isWindows(get, never):Bool;
	static private inline function get_isWindows():Bool
	{
		return (Sys.systemName() == "Windows");
	}

	public function new(path:String)
	{
		this.path = path;
	}

	/**
	 * Returns the directory as a path string
	 */
	public function toString():String
	{
		return path;
	}

	/**
	 * Add a segment to the path
	 * @param String segment The segment to add
	 * @return a new Directory instance
	 */
	public function add(segment:String):Directory
	{
		return new Directory(this.path + segment + SEPARATOR);
	}

	/**
	 * True if directory exists and is a directory
	 */
	public var exists(get, never):Bool;
	private inline function get_exists():Bool
	{
		return FileSystem.exists(path) && FileSystem.isDirectory(path);
	}

	/**
	 * Name of the last folder in the path
	 */
	public var lastFolder(get, never):String;
	private function get_lastFolder():String
	{
		return path.substr(0, -1).split(SEPARATOR).pop();
	}

	/**
	 * Create a directory if it doesn't already exist
	 * @param path the directory's path
	 * @return if the directory is successfully created
	 */
	public function create():Bool
	{
		if (!exists)
		{
			try
			{
				FileSystem.createDirectory(path);
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
	public function delete(recursive:Bool=true, ?path:String):Bool
	{
		if (path == null) path = this.path;
		if (exists)
		{
			if (!path.endsWith(Directory.SEPARATOR))
			{
				path += Directory.SEPARATOR;
			}

			if (recursive)
			{
				for (item in FileSystem.readDirectory(path))
				{
					var newPath = path + item;
					if (FileSystem.isDirectory(newPath))
					{
						delete(recursive, newPath);
					}
					else
					{
						FileSystem.deleteFile(newPath);
					}
				}
			}
			FileSystem.deleteDirectory(path);
			return true;
		}
		return false;
	}

	/**
	 * Create a temporary folder
	 * @return A Directory object with the created temp path
	 */
	static public function createTemporary():Directory
	{
		var tmp = Sys.getEnv("TEMP");
		if (tmp == null) tmp = "/tmp";
		var path:String;
		do {
			var crypt = haxe.crypto.Md5.encode(Std.string(Date.now())).substr(0, 10);
			path = tmp + SEPARATOR + "helm_" + crypt + SEPARATOR;
		} while (FileSystem.exists(path));
		return new Directory(path);
	}

}
