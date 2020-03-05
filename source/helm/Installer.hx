package helm;

import helm.util.L10n;
import helm.ds.PackageInfo;
import helm.install.Requirement;

class Installer {
	var installed = [];

	public function new() {
		var lockfile = Helm.project.lockfile();
	}

	function installDependencies(installDir:Path) {
		// install any dependencies
		var info = PackageInfo.load(installDir);
		if (info != null && info.dependencies != null) {
			install([for (require in info.dependencies) require]);
		}
	}

	function addToPackageDependencies(name:String, version:String, target:Path):Void {
		var info = PackageInfo.load(target);
		if (info != null) {
			info.addDependency(name, version);
			info.save(info.filePath);
		}
	}

	function installRequirement(requirement:Requirement):Bool {
		var name = requirement.name;
		// check if something was installed
		if (!requirement.install()) {
			Helm.logger.error("Could not install package " + name);
			return false;
		} else {
			// addToPackageDependencies(req.name, req.original, baseRepo);
			installDependencies(requirement.installPath);
			return true;
		}
	}

	public function install(packages:Array<String>) {
		for (name in packages) {
			var requirement = Requirement.fromString(name);
			// prevent installing a library already installed (infinite loop)
			if (requirement.isInstalled()) {
				Helm.logger.log(L10n.get("already_installed", [requirement]));
			} else {
				installRequirement(requirement);
			}
		}
	}
}
