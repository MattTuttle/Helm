package helm;

import sys.FileSystem as FS;
import sys.io.File;

using StringTools;

class FileSystem {
	/**
	 * The separator character to use between folders (/ vs \)
	 */
	static public var SEPARATOR(get, never):String;

	static private inline function get_SEPARATOR():String {
		return isWindows ? "\\" : "/";
	}

	/**
	 * The home directory of user (os specific)
	 */
	static public var homeDir(get, never):Path;

	static private function get_homeDir():Path {
		var path:Path = if (isWindows) {
			var home:Path = Sys.getEnv("HOMEDRIVE");
			home.join(Sys.getEnv("HOMEPATH"));
		} else {
			Sys.getEnv("HOME");
		}
		return path.normalize();
	}

	static private var isWindows(get, never):Bool;

	static private inline function get_isWindows():Bool {
		return (Sys.systemName() == "Windows");
	}

	static public inline function isFile(path:Path):Bool {
		return FS.exists(path) && !FS.isDirectory(path);
	}

	static public inline function isDirectory(path:Path):Bool {
		return FS.exists(path) && FS.isDirectory(path);
	}

	static public function rename(oldPath:Path, newPath:Path):Void {
		FS.rename(oldPath, newPath);
	}

	static public function copy(oldPath:Path, newPath:Path):Void {
		if (isDirectory(oldPath)) {
			for (item in readDirectory(oldPath)) {
				copy(oldPath.join(item), newPath.join(item));
			}
		} else {
			FileSystem.createDirectory(newPath.dirname());
			// TODO: read in chunks to better handle larger files
			var bytes = File.getBytes(oldPath);
			File.saveBytes(newPath, bytes);
		}
	}

	/**
	 * Create a directory if it doesn't already exist
	 * @param path the directory's path
	 * @return if the directory is successfully created
	 */
	static public function createDirectory(path:Path, recursive:Bool = false):Bool {
		if (isDirectory(path)) {
			return false;
		} else {
			try {
				FS.createDirectory(path);
				return true;
			} catch (e:Dynamic) {
				return false;
			}
		}
	}

	/**
	 * Recursively delete directory contents and the directory itself
	 * @param path the directory's path
	 * @return if the directory is successfully deleted
	 */
	static public function delete(path:Path, recursive:Bool = true):Bool {
		if (isDirectory(path)) {
			if (!path.endsWith(FileSystem.SEPARATOR)) {
				path = path + FileSystem.SEPARATOR;
			}

			if (recursive) {
				for (item in FS.readDirectory(path)) {
					delete(path.join(item), recursive);
				}
			}
			FS.deleteDirectory(path);
			return true;
		} else if (isFile(path)) {
			FS.deleteFile(path);
			return true;
		}
		return false;
	}

	static public function readDirectory(path:Path):Array<String> {
		return isDirectory(path) ? FS.readDirectory(path) : [];
	}

	/**
	 * Create a temporary folder
	 * @return A Directory object with the created temp path
	 */
	static public function createTemporary():Path {
		var tmp = Sys.getEnv("TEMP");
		if (tmp == null)
			tmp = "/tmp";
		var path:String;
		do {
			var crypt = haxe.crypto.Md5.encode(Std.string(Date.now())).substr(0, 10);
			path = tmp + SEPARATOR + "helm_" + crypt + SEPARATOR;
		} while (FS.exists(path));
		FS.createDirectory(path);
		return path;
	}
}
