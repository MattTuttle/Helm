package helm;

import sys.io.File;
import helm.FileSystem;
import helm.ds.PackageInfo;
import helm.ds.SemVer;

using StringTools;

class Repository {
	static public var LIB_DIR:String = ".haxelib";
	static public var NDLL_DIR:String = "ndll";

	public function new() {}

	public function findPackage(name:String):Null<String> {
		var repo = findPackagesIn(name, Sys.getCwd());
		// fallback, if no package found
		if (repo.length == 0) {
			repo = findPackagesIn(name, Config.globalPath);
			if (repo.length == 0)
				return null;
		}
		// TODO: resolve multiple packages found, select best one
		return repo[0].filePath;
	}

	function hasPackageNamed(path:Path, name:String):Bool {
		var info = PackageInfo.load(path);
		return (info != null && info.name == name);
	}

	function searchPackageList(name:String, l:Array<PackageInfo>):Array<PackageInfo> {
		var results = [];
		name = name.toLowerCase();
		for (item in l) {
			if (item.name.toLowerCase() == name) {
				results.push(item);
			}
		}
		return results;
	}

	public function findPackagesIn(name:String, target:Path):Array<PackageInfo> {
		name = name.toLowerCase();

		// search in the current directory for a haxelib.json file
		if (hasPackageNamed(target, name)) {
			var info = PackageInfo.load(target);
			if (info != null) {
				return [info];
			}
		}

		return searchPackageList(name, installed(target));
	}

	public function outdated(path:Path):List<{name:String, current:SemVer, latest:SemVer}> {
		// TODO: change this to a typedef and include more info
		var outdated = new List<{name:String, current:SemVer, latest:SemVer}>();
		for (item in installed(path)) {
			var info = Helm.registry.getProjectInfo(item.name);
			if (info == null)
				continue;
			var version:SemVer = info.currentVersion;
			if (version > item.version) {
				outdated.add({
					name: item.name,
					current: item.version,
					latest: version
				});
			}
		}
		return outdated;
	}

	function getPackageInfo(path:Path):Null<PackageInfo> {
		if (FileSystem.isFile(path.join(".current"))) {
			var version = File.getContent(path.join(".current")).trim().replace(".", ",");
			if (FileSystem.isDirectory(path.join(version))) {
				return PackageInfo.load(path.join(version));
			}
		}
		if (FileSystem.isFile(path.join(".dev"))) {
			path = File.getContent(path.join(".dev"));
			if (FileSystem.isDirectory(path)) {
				return PackageInfo.load(path);
			}
		}
		return null;
	}

	function findRoot(path:Path):Path {
		var search = path;
		while (search != "") {
			if (FileSystem.isDirectory(search.join(LIB_DIR))) {
				return search.join(LIB_DIR);
			}
			search = search.dirname();
		}
		// TODO: throw an error if we don't find the repository folder?
		return path.join(LIB_DIR);
	}

	/**
	 * Provides a list of all the packages installed in this repository
	 */
	public function installed(path:Path):Array<PackageInfo> {
		var packages = new Array<PackageInfo>();
		var dir = findRoot(path);
		for (item in FileSystem.readDirectory(dir)) {
			var libPath = dir.join(item);
			var info = getPackageInfo(libPath);
			if (info != null)
				packages.push(info);
		}
		return packages;
	}

	/**
	 * Returns a list of project dependencies based on files found in the directory
	 */
	public function findDependencies(dir:String):Array<String> {
		var libs = [];
		var info = PackageInfo.load(dir);
		if (info == null) {
			// search files for libraries to install
			for (item in FileSystem.readDirectory(dir)) {
				if (item.endsWith("hxml")) {
					for (line in File.getContent(item).split("\n")) {
						if (line.startsWith("-lib")) {
							var result = line.split(" ").pop();
							if (result != null) {
								var lib = result.split("=");
								if (lib.length > 1) {
									libs.push(lib[0] + ":" + lib[1]);
								} else {
									libs.push(lib[0]);
								}
							}
						}
					}
				} else if (item.endsWith("xml") || item.endsWith("nmml")) {
					var xml = Xml.parse(File.getContent(item));
					for (element in xml.firstElement().elements()) {
						if (element.nodeName == "haxelib") {
							// TODO: get version from lime xml?
							libs.push(element.get("name"));
						}
					}
				}
			}
		} else {
			for (version in info.dependencies) {
				libs.push(version);
			}
		}
		return libs;
	}
}
