package helm.install;

import helm.ds.PackageInfo;

class FilePath implements Installable {
	public final name:String;

	var path:Path;

	public function new(name:String, path:Path) {
		this.name = name;
		this.path = path;
	}

	/** installing from a path (C:\User\mypackage) */
	@:requirement
	public static function fromString(requirement:String):Null<Installable> {
		if (FileSystem.isDirectory(requirement)) {
			var info = PackageInfo.load(requirement);
			if (info != null) {
				return new FilePath(info.name, requirement);
			}
		}
		return null;
	}

	public function isInstalled():Bool {
		var packages = Helm.repository.findPackagesIn(name);
		return packages.length > 0;
	}

	public function install(target:Path, detail:Requirement):Bool {
		var info = PackageInfo.load(path);
		if (info != null) {
			// TODO: create symlink on unix platforms
			FileSystem.copy(path, target);
			detail.resolved = path;
			detail.version = info.version;
		}
		return true;
	}
}
