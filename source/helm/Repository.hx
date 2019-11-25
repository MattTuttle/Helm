package helm;

import haxe.Http;
import haxe.ds.StringMap;
import sys.io.File;
import sys.FileSystem;
import helm.ds.Types;
import helm.ds.PackageInfo;
import helm.ds.SemVer;
import helm.http.DownloadProgress;
import helm.util.*;

using StringTools;

class Repository
{

	static public var LIB_DIR:String = "haxe_libs";
	static public var NDLL_DIR:String = "ndll";

	// TODO: setup a mirror list for multiple repository servers
	#if haxelib
	static public var server:org.haxe.lib.Haxelib = new org.haxe.lib.Haxelib();
	#else
	static public var server = new Server();
	#end

	static public function findPackage(name:String):String
	{
		var repo = findPackageIn(name, Sys.getCwd());
		// fallback, if no package found
		if (repo.length == 0)
		{
			repo = findPackageIn(name, Config.globalPath);
			if (repo.length == 0)
				return null;
		}
		// TODO: resolve multiple packages found, select best one
		return repo[0].path;
	}

	static private function hasPackageNamed(path:Path, name:String):Bool
	{
		var info = PackageInfo.load(path);
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

	static public function getPackageRoot(path:Path, ?find:String):String
	{
		if (find == null) find = org.haxe.lib.Data.JSON;
		if (path != "")
		{
			if (FileSystem.exists(path.join(find)))
			{
				return path;
			}
			path = path.basename();
		}
		return null;
	}

	static public function findPackageIn(name:String, target:Path):Array<PackageInfo>
	{
		name = name.toLowerCase();

		// search in the current directory for a haxelib.json file
		if (hasPackageNamed(target, name))
		{
			return [PackageInfo.load(target)];
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

	static public function list(path:String):Array<PackageInfo>
	{
		var packages = new Array<PackageInfo>();
		var dir = new Directory(path).add(LIB_DIR);
		if (dir.exists)
		{
			for (item in FileSystem.readDirectory(dir.path))
			{
				var info = PackageInfo.load(dir.add(item).path);
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
		var info = PackageInfo.load(dir);
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
		var info = PackageInfo.load(path);
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

	static public function include(name:String):Array<String>
	{
		var root = getPackageRoot(Sys.getCwd());
		var path = hasPackageNamed(root, name) ? root : findPackage(name);

		var result = [];
		if (path != null && FileSystem.exists(path))
		{
			var info = PackageInfo.load(path);
			var lib = path + NDLL_DIR + Directory.SEPARATOR;
			if (FileSystem.exists(lib))
			{
				result.push("-L " + lib);
			}
			result.push(path + info.classPath);
			result.push("-D " + name);
			for (name in info.dependencies.keys())
			{
				result = result.concat(include(name));
			}
		}
		else
		{
			Logger.log(L10n.get("not_installed", [name]));
		}
		return result;
	}

	static public function download(version:VersionInfo):String
	{
		var filename = version.url.split("/").pop();
		var cache = Config.cachePath + filename;

		// TODO: allow to redownload with --force argument
		if (!FileSystem.exists(cache))
		{
			new Directory(Config.cachePath).create();
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
			Logger.log(L10n.get("installing_package", [name + "@" + gitRepository]));

			var tmpDir = Directory.createTemporary();
			var path = tmpDir.path;
			var args = ["clone"];
			if (gitBranch != null)
			{
				args.push("-b");
				args.push(gitBranch);
			}
			args.push(gitRepository);
			args.push(path);
			Sys.command("git", args);
			var info = PackageInfo.load(path);
			if (info == null)
			{
				tmpDir.delete();
				Logger.error(L10n.get("not_a_package"));
			}
			else
			{
				// rename folder to the name of the project
				var installPath = target + LIB_DIR + Directory.SEPARATOR + info.name + Directory.SEPARATOR;
				var dir = new Directory(installPath);
				if (dir.exists)
				{
					dir.delete();
				}
				else
				{
					dir.create();
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
		// check if installing from a local file
		if (sys.FileSystem.exists(name))
		{
			path = name;
			// TODO: load project info
		}
		else if (installGit(name, target))
		{
			return;
		}

		// conflict resolution
		var info = server.getProjectInfo(name);
		if (info == null)
		{
			Logger.error(L10n.get("not_a_package"));
		}
		var dir = new Directory(target).add(LIB_DIR).add(info.name);
		if (dir.exists)
		{
			var info = PackageInfo.load(dir.path);
			if (info != null && (version == null || version == info.version))
			{
				Logger.error(L10n.get("already_installed", [info.fullName]));
			}
			else
			{
				dir.delete();
			}
		}

		var downloadVersion = getLatestVersion(info, version);
		if (downloadVersion == null)
		{
			Logger.error(L10n.get("version_not_found", [Std.string(version)]));
			return;
		}
		Logger.log(L10n.get("installing_package", [info.name + ":" + downloadVersion.value]));

		// download if not installing from a local file
		if (path == null)
		{
			path = download(downloadVersion);
		}

		// TODO: if zip fails to read, redownload or throw an error?
		var f = File.read(path, true);
		var zip = haxe.zip.Reader.readZip(f);
		f.close();
		var baseDir = locateBasePath(zip);
		dir.create();

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
				Logger.error(L10n.get("invalid_filename", [name]));
			}

			var slashIndex = name.lastIndexOf("/") + 1;
			var loc = dir.add(name.substr(0, slashIndex));
			loc.create();

			// skip unzip if not a file
			if (slashIndex >= name.length)
			{
				continue;
			}
			var file = name.substr(slashIndex);
			var data = haxe.zip.Reader.unzip(item);
			File.saveBytes(loc.path + file, data);
		}
		Logger.log("\n", false);

		// install any dependencies
		var info = PackageInfo.load(dir.path);
		for (name in info.dependencies.keys())
		{
			var version = info.dependencies.get(name);
			// prevent installing a library we already installed (infinite loop)
			install(name, version, target);
		}
	}

	// TODO: search for hxpm.json
	static private function locateBasePath(zip:List<haxe.zip.Entry>):String
	{
		for (f in zip)
		{
			if (StringTools.endsWith(f.fileName, org.haxe.lib.Data.JSON))
			{
				return f.fileName.substr(0, f.fileName.length - org.haxe.lib.Data.JSON.length);
			}
		}
		throw "No " + org.haxe.lib.Data.JSON + " found";
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
