import haxe.Http;
import haxe.ds.StringMap;
import sys.io.File;
import sys.FileSystem;
import ds.Types;
import ds.SemVer;
import ds.HaxelibData;

using StringTools;

class Repository extends haxe.remoting.Proxy<SiteApi>
{

	// TODO: setup a mirror list for multiple repository servers
	static public var LIB_DIR:String = "libs";
	static public var NDLL_DIR:String = "ndll";

	static public var url = "http://lib.haxe.org/";
	static public var apiVersion = "3.0";

	static public var server(get, never):Repository;
	static private function get_server():Repository
	{
		return new Repository(haxe.remoting.HttpConnection.urlConnect(url + "api/" + apiVersion + "/index.n").api);
	}

	static public function loadPackageInfo(path:String):PackageInfo
	{
		if (FileSystem.exists(path + HaxelibData.JSON))
		{
			var data = HaxelibData.readData(File.getContent(path + HaxelibData.JSON));
			return {
				name: Std.string(data.name).toLowerCase(),
				version: SemVer.ofString(data.version),
				packages: list(path),
				path: path
			};
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
				throw "Package " + name + " is not installed";
		}
		// TODO: resolve multiple packages
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

	static public function findPackageIn(name:String, target:String):Array<PackageInfo>
	{
		name = name.toLowerCase();

		// search in the current directory for a haxelib.json file
		if (hasPackageNamed(target, name))
		{
			return [loadPackageInfo(target)];
		}

		// find a libs directory in the current directory or a parent
		if (target.endsWith("/")) target = target.substr(0, -1);
		var parts = target.split(Directory.SEPARATOR);
		while (parts.length > 0)
		{
			target = parts.join(Directory.SEPARATOR) + Directory.SEPARATOR;
			if (FileSystem.exists(target)) break;
			parts.pop();
		}

		return searchPackageList(name, list(target));
	}

	static public function printPackages(list:Array<PackageInfo>, ?level:Array<Bool>):Void
	{
		if (level == null) level = [true];

		var numItems = list.length, i = 0;
		for (item in list)
		{
			i += 1;
			var start = "";
			level[level.length - 1] = (i == numItems);
			for (j in 0...level.length - 1)
			{
				start += (level[j] ? "  " : "│ ");
			}
			var hasChildren = item.packages.length > 0;
			var separator = (i == numItems ? "└" : "├") + (hasChildren ? "─┬ " : "── ");
			Logger.log(start + separator + item.name + "@" + item.version);

			if (hasChildren)
			{
				level.push(true);
				printPackages(item.packages, level);
				level.pop();
			}
		}
	}

	static public function outdated(path:String):List<{name:String, current:SemVer, latest:SemVer}>
	{
		// TODO: change this to a typedef and include more info
		var outdated = new List<{name:String, current:SemVer, latest:SemVer}>();
		for (item in list(path))
		{
			var info = server.infos(item.name);
			var version:SemVer = info.curversion;
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
	static public function findDependencies(dir:String):StringMap<SemVer>
	{
		var libs = new StringMap<SemVer>();
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
				var data = HaxelibData.readData(File.getContent(item));
				for (lib in data.dependencies)
				{
					libs.set(lib.name, lib.version != "" ? SemVer.ofString(lib.version) : null);
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
			var data = HaxelibData.readData(File.getContent(target + HaxelibData.JSON));
			for (dependency in data.dependencies)
			{
				printInclude(dependency.name, target);
			}
		}
		else
		{
			throw "Package '" + name + "' is not installed.";
		}
	}

	static public function download(name:String, version:SemVer):String
	{
		var info = server.infos(name);
		var url = fileURL(info, version);
		if (url == null)
		{
			throw "Could not find package " + name + "@" + version;
		}

		var filename = url.split("/").pop();
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
			var http = new Http(url);
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
			if (version != info.version)
			{
				Directory.delete(target);
			}
			else
			{
				Logger.log("Package " + name + "@" + info.version + " already installed");
				return;
			}
		}

		if (gitRepository != null)
		{
			// TODO: rename folder to the name of the project
			var args = ["clone", gitRepository, target];
			Sys.command("git", args);
			return;
		}

		Logger.log("Installing " + name);

		var path = download(name, version);

		var f = File.read(path, true);
		var zip = haxe.zip.Reader.readZip(f);
		f.close();
		var infos = HaxelibData.readInfos(zip);
		var basepath = HaxelibData.locateBasePath(zip);
		Directory.create(target);

		var totalItems = zip.length,
			unzippedItems = 0;
		for (item in zip)
		{
			var percent = unzippedItems++ / totalItems;
			var progress = StringTools.rpad(StringTools.lpad(">", "-", Math.round(20 * percent)), " ", 20);
			Logger.log("Unpacking [" + progress + "] " + unzippedItems + "/" + totalItems + "\r", false);

			var name = item.fileName;
			if (name.startsWith(basepath))
			{
				// remove basepath
				name = name.substr(basepath.length, name.length - basepath.length);
				if (name.charAt(0) == "/" || name.charAt(0) == "\\" || name.split("..").length > 1)
					throw "Invalid filename : " + name;
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
		for (d in infos.dependencies)
		{
			// prevent installing a library we already installed (infinite loop)
			if (!installed.exists(d.name))
			{
				install(d.name, d.version, target, installed);
			}
		}
	}

	static public function fileURL(info:ProjectInfo, version:SemVer=null):String
	{
		var versionString:String = null;

		if (version == null)
		{
			var version:SemVer = info.curversion;
			// prevent automatic downloads of development versions
			var i = info.versions.length;
			while (version.preRelease != null && --i > 0)
			{
				version = info.versions[i].name;
			}
			versionString = version;
		}
		else
		{
			for (v in info.versions)
			{
				if (SemVer.ofString(v.name) == version)
				{
					versionString = version;
					break;
				}
			}
		}

		if (versionString != null)
		{
			// files stored on server use commas instead of periods
			versionString = versionString.split(".").join(",");

			// TODO: return this information from the server instead of creating it on the client
			return url + "files/" + apiVersion + "/" + info.name + "-" + versionString + ".zip";
		}
		return null;
	}

}
