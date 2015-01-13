package helm;

import sys.FileSystem;

using StringTools;

class Directory
{

	static public var SEPARATOR:String = "/";

	/**
	 * Create a directory if it doesn't already exist
	 * @param path the directory's path
	 * @return if the directory is successfully created
	 */
	static public function create(dir:String):Bool
	{
		if (!FileSystem.exists(dir))
		{
			try
			{
				FileSystem.createDirectory(dir);
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
	static public function delete(path:String):Bool
	{
		if (FileSystem.exists(path) && FileSystem.isDirectory(path))
		{
			if (!path.endsWith(Directory.SEPARATOR))
			{
				path += Directory.SEPARATOR;
			}

			for (item in FileSystem.readDirectory(path))
			{
				var path = path + item;
				if (FileSystem.isDirectory(path))
				{
					delete(path);
				}
				else
				{
					FileSystem.deleteFile(path);
				}
			}
			FileSystem.deleteDirectory(path);
			return true;
		}
		return false;
	}

}
