package helm;

import helm.install.Installable;
import helm.util.L10n;
import helm.ds.Types.ProjectInfo;
import helm.ds.SemVer;
import sys.io.File;
import helm.ds.PackageInfo;
import helm.install.Requirement;
import helm.ds.Lockfile;

using StringTools;

class Installer {
	static var versionDir = "helm";

	public function new() {}

	function getInstallPath(target:Path, name:String) {
		return target.join(Repository.LIB_DIR).join(name).join(versionDir);
	}

	function saveCurrentFile(dir:Path):Bool {
		if (dir != null && FileSystem.isDirectory(dir)) {
			File.saveContent(dir.dirname().join(".current"), versionDir);
			return true;
		}
		return false;
	}

	function installDependencies(installDir:Path, target:Path, lockfile:Lockfile) {
		// install any dependencies
		var info = PackageInfo.load(installDir);
		if (info != null && info.dependencies != null) {
			for (require in info.dependencies) {
				install(require, target, lockfile);
			}
		}
	}

	function addToPackageDependencies(name:String, version:String, target:Path):PackageInfo {
		var info = PackageInfo.load(target);
		info.addDependency(name, version);
		info.save(info.filePath);
		return info;
	}

	function libraryIsInstalled(requirement:Requirement, target:Path):Bool {
		var packages = Helm.repository.findPackagesIn(requirement.name, target);
		if (requirement.version == null) {
			for (info in packages) {
				// TODO: break or throw error if more than one package?
				requirement.version = info.version;
			}
		}
		return packages.length > 0;
	}

	function installFromType(requirement:Requirement, baseRepo:Path, lockfile:Lockfile):Bool {
		var path = getInstallPath(baseRepo, requirement.name);
		// check if something was installed
		if (requirement.install(path) && !saveCurrentFile(path)) {
			Helm.logger.error("Could not install package " + requirement.name);
			return false;
		}

		// addToPackageDependencies(req.name, req.original, baseRepo);
		installDependencies(path, baseRepo, lockfile);
		return true;
	}

	public function install(packageInstall:String, ?target:Path, ?lockfile:Lockfile):Bool {
		final path = target == null ? Config.globalPath : target;
		if (lockfile == null) {
			lockfile = new Lockfile();
		}
		var requirement = new Requirement(packageInstall);
		// prevent installing a library already installed (infinite loop)
		if (libraryIsInstalled(requirement, path)) {
			Helm.logger.log(L10n.get("already_installed", [requirement]));
		} else {
			if (installFromType(requirement, path, lockfile)) {
				lockfile.addRequirement(requirement);
				lockfile.save(path);
			}
		}
		return false;
	}
}
