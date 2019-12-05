package helm;

import haxe.Http;
import haxe.ds.StringMap;
import sys.io.File;
import helm.FileSystem;
import helm.ds.Types;
import helm.ds.PackageInfo;
import helm.ds.SemVer;
import helm.http.DownloadProgress;
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
		var repo = findPackagesIn(name, Sys.getCwd());
		// fallback, if no package found
		if (repo.length == 0)
		{
			repo = findPackagesIn(name, Config.globalPath);
			if (repo.length == 0)
				return null;
		}
		// TODO: resolve multiple packages found, select best one
		return repo[0].filePath;
	}

	function hasPackageNamed(path:Path, name:String):Bool
	{
		var info = PackageInfo.load(path);
		return (info != null && info.name == name);
	}

	function searchPackageList(name:String, l:Array<PackageInfo>):Array<PackageInfo>
	{
		var results = [];
		for (item in l)
		{
			if (item.name == name)
			{
				results.push(item);
			}
			for (result in searchPackageList(name, list(item.filePath)))
			{
				results.push(result);
			}
		}
		return results;
	}

	public function getPackageRoot(path:Path, ?find:String):String
	{
		if (find == null) find = PackageInfo.JSON;
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

	public function findPackagesIn(name:String, target:Path):Array<PackageInfo>
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
			var info = Helm.registry.getProjectInfo(item.name);
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

}
