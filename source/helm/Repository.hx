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

	static public var LIB_DIR:String = "libs";
	static public var NDLL_DIR:String = "ndll";

	// TODO: setup a mirror list for multiple repository servers
	static public var server:haxelib.Haxelib = new haxelib.Haxelib();

	static public function loadPackageInfo(path:String):PackageInfo
	{
		if (FileSystem.exists(path + haxelib.Data.JSON))
		{
			var data = new haxelib.Data();
			data.read(File.getContent(path + haxelib.Data.JSON));
			return new PackageInfo(Std.string(data.name).toLowerCase(),
				SemVer.ofString(data.version), data.dependencies, path, data.mainClass);
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
				return null;
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
			for (result in searchPackageList(name, list(item.path)))
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
		var info = loadPackageInfo(dir);
		if (info == null)
		{
			// search files for libraries to install
			for (item in FileSystem.readDirectory(dir))
			{
				if (item.endsWith("hxml"))
				{
					for (line in File.getContent(item).split("\n"))
					{
						if (line.startsWith("-lib"))
						{
							var lib = line.split(" ").pop().split("=");
							libs.set(lib[0], lib.length > 1 ? lib[1] : null);
						}
					}
				}
				else if (item.endsWith("xml") || item.endsWith("nmml"))
				{
					var xml = Xml.parse(File.getContent(item));
					for (element in xml.firstElement().elements())
					{
						if (element.nodeName == "haxelib")
						{
							var lib = element.get("name");
							// TODO: get version from lime xml?
							libs.set(lib, null);
						}
					}
				}
			}
		}
		else
		{
			for (name in info.dependencies.keys())
			{
				var version = info.dependencies.get(name);
				libs.set(name, version);
			}
		}
		return libs;
	}

	static public function run(args:Array<String>, path:String, useEnvironment:Bool=false):Int
	{
		var info = Repository.loadPackageInfo(path);
		if (info == null)
		{
			Logger.log(L10n.get("not_a_package"));
			return 1;
		}

		var command:String;
		if (info.mainClass != null)
		{
			command = "haxe";
			for (name in info.dependencies.keys())
			{
				args.push("-lib");
				args.push(name);
			}
			args.unshift(info.mainClass);
			args.unshift("--run");
		}
		else
		{
			command = "neko";
			if (!FileSystem.exists(path + "run.n"))
			{
				Logger.log(L10n.get("run_not_enabled", [info.name]));
				return 1;
			}
			else
			{
				args.unshift("run.n");
			}
		}

		if (useEnvironment)
		{
			Sys.putEnv("HAXELIB_RUN", Sys.getCwd());
		}
		else
		{
			args.push(Sys.getCwd());
			Sys.putEnv("HAXELIB_RUN", "1");
		}

		Sys.setCwd(path);
		return Sys.command(command, args);
	}

	static public function printInclude(name:String, target:String=null):Void
	{
		var path = (target == null ? findPackage(name) : LIB_DIR + Directory.SEPARATOR + name + Directory.SEPARATOR);

		if (path != null && FileSystem.exists(path))
		{
			var lib = path + NDLL_DIR + Directory.SEPARATOR;
			if (FileSystem.exists(lib))
			{
				Logger.log("-L " + lib);
			}
			Logger.log(path);
			Logger.log("-D " + name);
			var info = loadPackageInfo(path);
			for (name in info.dependencies.keys())
			{
				printInclude(name, target);
			}
		}
		else
		{
			Logger.log(L10n.get("not_installed", [name]));
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

	static public function installGit(name:String, target:String):Bool
	{
		var gitRepository = null,
			gitBranch = null,
			installed = false;

		if (name.startsWith("git+"))
		{
			var parts = name.split("#");
			if (parts.length > 1) gitBranch = parts.pop();
			gitRepository = parts[0].substr(4);
			name = gitRepository.substr(gitRepository.lastIndexOf("/") + 1).replace(".git", "");
		}
		else if (name.split("/").length == 2) // <User>/<Repository>
		{
			var parts = name.split("#");
			if (parts.length > 1) gitBranch = parts.pop();
			gitRepository = "https://github.com/" + parts[0] + ".git";
			name = parts[0].split("/").pop();
		}

		if (gitRepository != null)
		{
			var path = Directory.createTemporary();
			var args = ["clone"];
			if (gitBranch != null)
			{
				args.push("-b");
				args.push(gitBranch);
			}
			args.push(gitRepository);
			args.push(path);
			Sys.command("git", args);
			var info = loadPackageInfo(path);
			if (info == null)
			{
				Directory.delete(path);
				throw L10n.get("not_a_package");
			}
			else
			{
				// rename folder to the name of the project
				var installPath = target + LIB_DIR + Directory.SEPARATOR + info.name + Directory.SEPARATOR;
				if (FileSystem.exists(installPath))
				{
					Directory.delete(installPath);
				}
				else
				{
					Directory.create(installPath);
				}
				FileSystem.rename(path, installPath);
				installed = true;
			}
		}
		return installed;
	}

	static public function install(name:String, ?version:SemVer, target:String=""):Void
	{
		var path = null;
		if (name.startsWith("file+"))
		{
			path = name.substr(5);
		}
		else if (installGit(name, target)) return;

		// conflict resolution
		var info = server.getProjectInfo(name);
		if (info == null)
		{
			Logger.log(L10n.get("not_a_package"));
			return;
		}
		var installPath = target + LIB_DIR + Directory.SEPARATOR + info.name + Directory.SEPARATOR;
		if (FileSystem.exists(installPath))
		{
			var info = loadPackageInfo(installPath);
			if (info != null && (version == null || version == info.version))
			{
				Logger.log(L10n.get("already_installed", [info.fullName]));
				return;
			}
			else
			{
				Directory.delete(installPath);
			}
		}

		var version = getLatestVersion(info, version);
		Logger.log(L10n.get("installing_package", [info.name + "@" + version.value]));

		// download if not installing from a local file
		if (path == null)
		{
			path = download(version);
		}

		// TODO: if zip fails to read, redownload or throw an error?
		var f = File.read(path, true);
		var zip = haxe.zip.Reader.readZip(f);
		f.close();
		var baseDir = haxelib.Data.locateBasePath(zip);
		Directory.create(installPath);

		var totalItems = zip.length,
			unzippedItems = 0;
		for (item in zip)
		{
			var percent = ++unzippedItems / totalItems;
			var progress = StringTools.rpad(StringTools.lpad(">", "-", Math.floor(60 * percent)), " ", 60);
			Logger.log('[$progress] $unzippedItems/$totalItems\r', false);

			// strip first directory if any
			var name = item.fileName.replace("\\", "/").substr(baseDir.length);
			if (name.charAt(0) == "/" || name.split("..").length > 1)
			{
				throw L10n.get("invalid_filename", [name]);
			}

			var slashIndex = name.lastIndexOf("/") + 1;
			var dir = installPath + name.substr(0, slashIndex);
			Directory.create(dir);

			// skip unzip if not a file
			if (slashIndex >= name.length)
			{
				continue;
			}
			var file = name.substr(slashIndex);
			var data = haxe.zip.Reader.unzip(item);
			File.saveBytes(dir + file, data);
		}
		Logger.log("\n", false);

		// install any dependencies
		var info = loadPackageInfo(installPath);
		for (name in info.dependencies.keys())
		{
			var version = info.dependencies.get(name);
			// prevent installing a library we already installed (infinite loop)
			install(name, version, target);
		}
	}

	static private function getLatestVersion(info:ProjectInfo, version:SemVer=null):VersionInfo
	{
		if (version == null)
		{
			// TODO: sort versions?
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
