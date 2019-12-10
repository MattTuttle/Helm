package helm.install;

import helm.ds.PackageInfo;
import helm.util.L10n;

class Git implements Installable {
	var url:String;
	var branch:Null<String>;

	public function new(url:String, branch:Null<String>) {
		this.url = url;
		this.branch = branch;
	}

	public function install(target:Path, name:String):Bool {
		Helm.logger.log(L10n.get("installing_package", [name + "@" + url]));

		var tmpDir = FileSystem.createTemporary();
		var path = tmpDir;
		var args = ["clone"];
		if (branch != null) {
			args.push("-b");
			args.push(branch);
		}
		args.push(url);
		args.push(path);
		// TODO: better handling when git not installed
		Sys.command("git", args);
		var info = PackageInfo.load(path);
		if (info == null) {
			FileSystem.delete(tmpDir);
			Helm.logger.error(L10n.get("not_a_package"));
		} else {
			moveToRepository(path, target);
			return true;
		}
		return false;
	}

	function moveToRepository(path:Path, installPath:Path) {
		if (FileSystem.isDirectory(installPath)) {
			FileSystem.delete(installPath);
		} else {
			FileSystem.createDirectory(installPath);
		}
		FileSystem.rename(path, installPath);
	}
}
