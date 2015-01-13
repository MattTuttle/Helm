package helm;

import haxe.Http;
import haxe.ds.StringMap;
import sys.io.File;
import sys.FileSystem;
import helm.ds.Types;
import helm.ds.SemVer;

using StringTools;

class Repository
{

	// TODO: setup a mirror list for multiple repository servers
	static public var LIB_DIR:String = "libs";
	static public var NDLL_DIR:String = "ndll";

	static public var server:haxelib.Haxelib = new haxelib.Haxelib();

	static public function loadPackageInfo(path:String):PackageInfo
	{
		if (FileSystem.exists(path + haxelib.Data.JSON))
		{
			var data = new haxelib.Data();
			data.read(File.getContent(path + haxelib.Data.JSON));
			return new PackageInfo(Std.string(data.name).toLowerCase(),
				SemVer.ofString(data.version),
				list(path), path);
		}
		return null;
	}

	static public function findPackage(name:String):String
	{
		var repo = findPackageIn(name, Sys.getCwd());
		if (repo.length == 0)
		{
			repo = findPackageIn(name, Config.globalPath);
			if (repo.length == 0)
				throw L10n.get("not_installed", [name]);
		}
		// TODO: resolve multiple packages found, select best one
		return repo[0].path;
	}

	static private function hasPackageNamed(path:String, name:String):Bool
	{
		var info = loadPackageInfo(path);
		return (info != null && info.name == name);
	}

	static private function searchPackageList(name:String, l:Array<PackageInfo>):Array<PackageInfo>
	{
		var results = new Array<PackageInfo>();
		for (item in l)
		{
			if (item.name == name)
			{
				results.push(item);
			}
			for (result in searchPackageList(name, item.packages))
			{
				results.push(result);
			}
		}
		return results;
	}

	static public function getPackageRoot(path:String, find:String):String
	{
		if (path.endsWith("/")) path = path.substr(0, -1);
		var parts = path.split(Directory.SEPARATOR);
		while (parts.length > 0)
		{
			path = parts.join(Directory.SEPARATOR) + Directory.SEPARATOR;
			if (FileSystem.exists(path + find))
			{
				return path;
			}
			parts.pop();
		}
		return null;
	}

	static public function findPackageIn(name:String, target:String):Array<PackageInfo>
	{
		name = name.toLowerCase();

		// search in the current directory for a haxelib.json file
		if (hasPackageNamed(target, name))
		{
			return [loadPackageInfo(target)];
		}

		// find a libs directory in the current directory or a parent
		target = getPackageRoot(target, LIB_DIR + Directory.SEPARATOR);

		return searchPackageList(name, list(target));
	}

	static public function outdated(path:String):List<{name:String, current:SemVer, latest:SemVer}>
	{
		// TODO: change this to a typedef and include more info
		var outdated = new List<{name:String, current:SemVer, latest:SemVer}>();
		for (item in list(path))
		{
			var info = server.getProjectInfo(item.name);
			if (info == null) continue;
			var version:SemVer = info.currentVersion;
			if (version > item.version)
			{
				outdated.add({
					name: item.name,
					current: item.version,
					latest: version
				});
			}
		}
		return outdated;
	}

	static public function list(dir:String):Array<PackageInfo>
	{
		var packages = new Array<PackageInfo>();
		var libs = dir + LIB_DIR + Directory.SEPARATOR;
		if (FileSystem.exists(libs) && FileSystem.isDirectory(libs))
		{
			for (item in FileSystem.readDirectory(libs))
			{
				var path = libs + item + Directory.SEPARATOR;
				var info = loadPackageInfo(path);
				if (info != null) packages.push(info);
			}
		}
		return packages;
	}

	/**
	 * Returns a list of project dependencies based on files found in the directory
	 */
	static public function findDependencies(dir:String):StringMap<String>
	{
		var libs = new StringMap<String>();
		for (item in FileSystem.readDirectory(dir))
		{
			// search files for libraries to install
			if (item.endsWith("hxml"))
			{
				for (line in File.getContent(item).split("\n"))
				{
					if (line.startsWith("-lib"))
					{
						var lib = line.split(" ").pop().split("=");
						libs.set(lib[0], lib.length > 1 ? SemVer.ofString(lib[1]) : null);
					}
				}
			}
			else if (item.endsWith("json"))
			{
				var data = new haxelib.Data();
				data.read(File.getContent(item));
				for (name in data.dependencies.keys())
				{
					var version = data.dependencies.get(name);
					libs.set(name, version);
				}
			}
		}
		return libs;
	}

	static public function printInclude(name:String, target:String=null):Void
	{
		if (target == null) target = findPackage(name);
		else target += LIB_DIR + Directory.SEPARATOR + name + Directory.SEPARATOR;

		if (target != null && FileSystem.exists(target))
		{
			var lib = target + NDLL_DIR + Directory.SEPARATOR;
			if (FileSystem.exists(lib))
			{
				Logger.log("-L " + lib);
			}
			Logger.log(target);
			Logger.log("-D " + name);
			var data = new haxelib.Data();
			data.read(File.getContent(target + haxelib.Data.JSON));
			for (name in data.dependencies.keys())
			{
				printInclude(name, target);
			}
		}
		else
		{
			throw L10n.get("not_installed", [name]);
		}
	}

	static public function download(version:helm.ds.VersionInfo):String
	{
		var filename = version.url.split("/").pop();
		var cache = Config.cachePath + filename;

		// TODO: allow to redownload with --force argument
		if (!FileSystem.exists(cache))
		{
			Directory.create(Config.cachePath);
			// download as different name to prevent loading partial downloads if cancelled
			var downloadPath = cache.replace("zip", "part");

			// download the file and show progress
			var out = File.write(downloadPath, true);
			var progress = new DownloadProgress(out);
			var http = new Http(version.url);
			http.onError = function(error) {
				progress.close();
			};
			http.customRequest(false, progress);

			// move file from the downloads folder to cache (prevents corrupt zip files if cancelled)
			FileSystem.rename(downloadPath, cache);
		}

		return cache;
	}

	static public function install(name:String, ?version:SemVer, target:String="", ?installed:StringMap<PackageInfo>):Void
	{
		if (installed == null) installed = new StringMap<PackageInfo>();

		var gitRepository = null;
		if (name.startsWith("git+"))
		{
			gitRepository = name.substr(4);
			name = gitRepository.substr(gitRepository.lastIndexOf("/") + 1).replace(".git", "");
		}
		else if (name.split("/").length == 2) // <User>/<Repository>
		{
			gitRepository = "https://github.com/" + name + ".git";
			name = name.split("/").pop();
		}

		target += LIB_DIR + Directory.SEPARATOR + name + Directory.SEPARATOR;
		if (FileSystem.exists(target))
		{
			var info = loadPackageInfo(target);
			if (info != null && (version == null || version == info.version))
			{
				Logger.log(L10n.get("already_installed", [info.fullName]));
				return;
			}
			else
			{
				Directory.delete(target);
			}
		}

		if (gitRepository != null)
		{
			// TODO: rename folder to the name of the project
			var args = ["clone", gitRepository, target];
			Sys.command("git", args);
			return;
		}

		var info = server.getProjectInfo(name);
		var version = getLatestVersion(info, version);
		Logger.log(L10n.get("installing_package", [info.name + "@" + version.value]));
		var path = download(version);

		// TODO: if zip fails to read, redownload?
		var f = File.read(path, true);
		var zip = haxe.zip.Reader.readZip(f);
		f.close();
		var infos = haxelib.Data.readInfos(zip);
		var basepath = haxelib.Data.locateBasePath(zip);
		Directory.create(target);

		var totalItems = zip.length,
			unzippedItems = 0;
		for (item in zip)
		{
			var percent = ++unzippedItems / totalItems;
			var progress = StringTools.rpad(StringTools.lpad(">", "-", Math.floor(60 * percent)), " ", 60);
			Logger.log('[$progress] $unzippedItems/$totalItems\r', false);

			var name = item.fileName;
			if (name.startsWith(basepath))
			{
				// remove basepath
				name = name.substr(basepath.length, name.length - basepath.length);
				if (name.charAt(0) == "/" || name.charAt(0) == "\\" || name.split("..").length > 1)
					throw L10n.get("invalid_filename", [name]);
				var dirs = ~/[\/\\]/g.split(name);
				var path = "";
				var file = dirs.pop();
				for (dir in dirs)
				{
					path += dir;
					Directory.create(target + path);
					path += Directory.SEPARATOR;
				}
				if (file == "")
				{
					continue; // was just a directory
				}
				path += file;
				var data = haxe.zip.Reader.unzip(item);
				File.saveBytes(target + path, data);
			}
		}

		Logger.log("\n", false);

		installed.set(name, loadPackageInfo(target));
		for (name in infos.dependencies.keys())
		{
			var version = infos.dependencies.get(name);
			// prevent installing a library we already installed (infinite loop)
			if (!installed.exists(name))
			{
				install(name, version, target, installed);
			}
		}
	}

	static private function getLatestVersion(info:ProjectInfo, version:SemVer=null):VersionInfo
	{
		if (version == null)
		{
			for (v in info.versions)
			{
				if (v.value.preRelease == null)
				{
					return v;
				}
			}
		}
		else
		{
			for (v in info.versions)
			{
				if (v.value == version)
				{
					return v;
				}
			}
		}
		return null;
	}

}
