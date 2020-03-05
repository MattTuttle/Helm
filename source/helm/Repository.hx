package helm;

import sys.io.File;
import helm.FileSystem;
import helm.ds.PackageInfo;
import helm.ds.SemVer;

using StringTools;

class Repository {
	@:allow(helm.Helm) static var LIB_DIR:String = ".haxelib";
	static public var NDLL_DIR:String = "ndll";

	public final path:Path;

	public function new(?path:Path) {
		this.path = path == null ? Config.globalPath : path;
	}

	public function findPackage(name:String):Null<String> {
		var repo = findPackagesIn(name);
		// TODO: resolve multiple packages found, select best one
		return repo[0].filePath;
	}

	function hasPackageNamed(name:String):Bool {
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

	public function findPackagesIn(name:String):Array<PackageInfo> {
		name = name.toLowerCase();

		// search in the current directory for a haxelib.json file
		if (hasPackageNamed(name)) {
			var info = PackageInfo.load(path);
			if (info != null) {
				return [info];
			}
		}

		return searchPackageList(name, installed());
	}

	public function outdated():List<{name:String, current:SemVer, latest:SemVer}> {
		// TODO: change this to a typedef and include more info
		var outdated = new List<{name:String, current:SemVer, latest:SemVer}>();
		for (item in installed()) {
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

	/**
	 * Provides a list of all the packages installed in this repository
	 */
	public function installed():Array<PackageInfo> {
		var packages = new Array<PackageInfo>();
		for (item in FileSystem.readDirectory(path)) {
			var libPath = path.join(item);
			var info = getPackageInfo(libPath);
			if (info != null)
				packages.push(info);
		}
		return packages;
	}

	/**
	 * Returns a list of project dependencies based on files found in the directory
	 */
	public function findDependencies():Array<String> {
		var libs = [];
		var info = PackageInfo.load(path);
		if (info == null) {
			// search files for libraries to install
			for (item in FileSystem.readDirectory(path)) {
				if (item.endsWith("hxml")) {
					for (line in File.getContent(item).split("\n")) {
						if (line.startsWith("-lib")) {
							var result = line.split(" ").pop();
							if (result != null) {
								var lib = result.split("=");
								if (lib.length > 1) {
									libs.push(lib[0] + Config.VERSION_SEP + lib[1]);
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
