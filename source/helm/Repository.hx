package helm;

import haxe.Http;
import haxe.ds.StringMap;
import sys.io.File;
import helm.FileSystem;
import helm.ds.Types;
import helm.ds.PackageInfo;
import helm.ds.SemVer;
import helm.http.DownloadProgress;
import helm.haxelib.Data;
import helm.util.*;

using StringTools;

class Repository
{

	static public var LIB_DIR:String = ".haxelib";
	static public var NDLL_DIR:String = "ndll";

	public function new()
	{

	}

	public function findPackage(name:String):String
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

	function hasPackageNamed(path:Path, name:String):Bool
	{
		var info = PackageInfo.load(path);
		return (info != null && info.name == name);
	}

	function searchPackageList(name:String, l:Array<PackageInfo>):Array<PackageInfo>
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

	public function getPackageRoot(path:Path, ?find:String):String
	{
		if (find == null) find = Data.JSON;
		var original = path;
		// TODO: better string checking?
		while (path != "" && path != "/")
		{
			if (FileSystem.isFile(path.join(find)) || FileSystem.isDirectory(path.join(find)))
			{
				return path;
			}
			path = path.dirname();
		}
		return original;
	}

	public function findPackageIn(name:String, target:Path):Array<PackageInfo>
	{
		name = name.toLowerCase();

		// search in the current directory for a haxelib.json file
		if (hasPackageNamed(target, name))
		{
			return [PackageInfo.load(target)];
		}

		// find a libs directory in the current directory or a parent
		target = getPackageRoot(target, LIB_DIR);

		return searchPackageList(name, list(target));
	}

	public function outdated(path:String):List<{name:String, current:SemVer, latest:SemVer}>
	{
		// TODO: change this to a typedef and include more info
		var outdated = new List<{name:String, current:SemVer, latest:SemVer}>();
		for (item in list(path))
		{
			var info = Helm.server.getProjectInfo(item.name);
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

	function getPackageInfo(path:Path):Null<PackageInfo>
	{
		if (FileSystem.isFile(path.join(".current")))
		{
			var version = File.getContent(path.join(".current")).trim().replace(".", ",");
			if (FileSystem.isDirectory(path.join(version)))
			{
				return PackageInfo.load(path.join(version));
			}
		}
		if (FileSystem.isFile(path.join(".dev")))
		{
			path = File.getContent(path.join(".dev"));
			if (FileSystem.isDirectory(path))
			{
				return PackageInfo.load(path);
			}
		}
		return null;
	}

	public function list(path:Path):Array<PackageInfo>
	{
		var packages = new Array<PackageInfo>();
		var dir = path.join(LIB_DIR);
		for (item in FileSystem.readDirectory(dir))
		{
			var libPath = dir.join(item);
			var info = getPackageInfo(libPath);
			if (info != null) packages.push(info);
		}
		return packages;
	}

	/**
	 * Returns a list of project dependencies based on files found in the directory
	 */
	public function findDependencies(dir:String):StringMap<String>
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

	public function run(args:Array<String>, path:Path, useEnvironment:Bool=false):Int
	{
		var info = PackageInfo.load(path);
		if (info == null)
		{
			Helm.logger.log(L10n.get("not_a_package"));
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
			if (!FileSystem.isFile(path.join("run.n")))
			{
				Helm.logger.log(L10n.get("run_not_enabled", [info.name]));
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

		var originalPath = Sys.getCwd();
		Sys.setCwd(path);
		var result = Sys.command(command, args);
		Sys.setCwd(originalPath);
		return result;
	}

	public function include(name:String):Array<String>
	{
		var cwd:Path = Sys.getCwd();
		cwd = cwd.normalize();
		var root = getPackageRoot(cwd);
		var path:Path = hasPackageNamed(root, name) ? root : findPackage(name);

		var result = [];
		if (path != null && FileSystem.isDirectory(path))
		{
			var info = PackageInfo.load(path);
			var lib = path.join(NDLL_DIR);
			if (FileSystem.isDirectory(lib))
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
			Helm.logger.log(L10n.get("not_installed", [name]));
		}
		return result;
	}

	public function download(version:VersionInfo):String
	{
		var filename = version.url.split("/").pop();
		var cache = Config.cachePath + filename;

		// TODO: allow to redownload with --force argument
		if (!FileSystem.isDirectory(cache))
		{
			FileSystem.create(Config.cachePath);
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

	public function installGit(name:String, target:Path):Bool
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
			Helm.logger.log(L10n.get("installing_package", [name + "@" + gitRepository]));

			var tmpDir = FileSystem.createTemporary();
			var path = tmpDir;
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
				FileSystem.delete(tmpDir);
				Helm.logger.error(L10n.get("not_a_package"));
			}
			else
			{
				// rename folder to the name of the project
				var installPath = target.join(LIB_DIR).join(info.name);
				if (FileSystem.isDirectory(installPath))
				{
					FileSystem.delete(installPath);
				}
				else
				{
					FileSystem.create(installPath);
				}
				FileSystem.rename(path, installPath);
				installed = true;
			}
		}
		return installed;
	}

	public function install(name:String, ?version:SemVer, ?target:Path):Void
	{
		if (target == null) target = "";
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
		var info = Helm.server.getProjectInfo(name);
		if (info == null)
		{
			Helm.logger.error(L10n.get("not_a_package"));
		}
		var dir = target.join(LIB_DIR).join(info.name);
		if (FileSystem.isDirectory(dir))
		{
			var info = PackageInfo.load(dir);
			if (info != null && (version == null || version == info.version))
			{
				Helm.logger.error(L10n.get("already_installed", [info.fullName]));
			}
			else
			{
				FileSystem.delete(dir);
			}
		}

		var downloadVersion = getLatestVersion(info, version);
		if (downloadVersion == null)
		{
			Helm.logger.error(L10n.get("version_not_found", [Std.string(version)]));
			return;
		}
		Helm.logger.log(L10n.get("installing_package", [info.name + ":" + downloadVersion.value]));

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
		FileSystem.create(dir);

		var totalItems = zip.length,
			unzippedItems = 0;
		for (item in zip)
		{
			var percent = ++unzippedItems / totalItems;
			var progress = StringTools.rpad(StringTools.lpad(">", "-", Math.floor(60 * percent)), " ", 60);
			Helm.logger.log('[$progress] $unzippedItems/$totalItems\r', false);

			// strip first directory if any
			var name = item.fileName.replace("\\", "/").substr(baseDir.length);
			if (name.charAt(0) == "/" || name.split("..").length > 1)
			{
				Helm.logger.error(L10n.get("invalid_filename", [name]));
			}

			var slashIndex = name.lastIndexOf("/") + 1;
			var loc = dir.join(name.substr(0, slashIndex));
			FileSystem.create(loc);

			// skip unzip if not a file
			if (slashIndex >= name.length)
			{
				continue;
			}
			var file = name.substr(slashIndex);
			var data = haxe.zip.Reader.unzip(item);
			File.saveBytes(loc.join(file), data);
		}
		Helm.logger.log("\n", false);

		// install any dependencies
		var info = PackageInfo.load(dir);
		for (name in info.dependencies.keys())
		{
			var version = info.dependencies.get(name);
			// prevent installing a library we already installed (infinite loop)
			install(name, version, target);
		}
	}

	// TODO: search for hxpm.json
	function locateBasePath(zip:List<haxe.zip.Entry>):String
	{
		for (f in zip)
		{
			if (StringTools.endsWith(f.fileName, Data.JSON))
			{
				return f.fileName.substr(0, f.fileName.length - Data.JSON.length);
			}
		}
		throw "No " + Data.JSON + " found";
	}

	function getLatestVersion(info:ProjectInfo, version:SemVer=null):VersionInfo
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
