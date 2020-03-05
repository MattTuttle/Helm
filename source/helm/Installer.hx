package helm;

import helm.util.L10n;
import sys.io.File;
import helm.ds.PackageInfo;
import helm.install.Requirement;

class Installer {
	static var versionDir = "helm";

	public function new() {}

	function getInstallPath(name:String) {
		return Helm.repository.path.join(name).join(versionDir);
	}

	function saveCurrentFile(dir:Path):Bool {
		if (dir != null && FileSystem.isDirectory(dir)) {
			File.saveContent(dir.dirname().join(".current"), versionDir);
			return true;
		}
		return false;
	}

	function installDependencies(installDir:Path) {
		// install any dependencies
		var info = PackageInfo.load(installDir);
		if (info != null && info.dependencies != null) {
			for (require in info.dependencies) {
				install(require);
			}
		}
	}

	function addToPackageDependencies(name:String, version:String, target:Path):Void {
		var info = PackageInfo.load(target);
		if (info != null) {
			info.addDependency(name, version);
			info.save(info.filePath);
		}
	}

	function installFromType(requirement:Requirement):Bool {
		var name = requirement.installable.name;
		var path = getInstallPath(name);
		// check if something was installed
		if (requirement.install(path) && !saveCurrentFile(path)) {
			Helm.logger.error("Could not install package " + name);
			return false;
		}

		// addToPackageDependencies(req.name, req.original, baseRepo);
		installDependencies(path);
		return true;
	}

	public function install(packageInstall:String):Bool {
		var lockfile = Helm.project.lockfile();
		var requirement = Requirement.fromString(packageInstall);
		// prevent installing a library already installed (infinite loop)
		if (requirement.installable.isInstalled()) {
			Helm.logger.log(L10n.get("already_installed", [requirement]));
		} else {
			return installFromType(requirement);
		}
		return false;
	}
}
