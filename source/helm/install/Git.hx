package helm.install;

import sys.io.Process;
import helm.ds.PackageInfo;
import helm.util.L10n;

using StringTools;

class Git implements Installable {
	public final name:String;

	var url:String;
	var branch:Null<String>;

	public function new(name:String, url:String, branch:Null<String>) {
		this.name = name;
		this.url = url;
		this.branch = branch;
	}

	/** installing from a git url (git+http://mygitserver.com/repo.git) */
	@:requirement
	public static function checkGit(requirement:String):Null<Installable> {
		if (requirement.startsWith("git+")) {
			var parts = requirement.split("#");
			var branch = null;
			if (parts.length > 1)
				branch = parts.pop();
			var url = parts[0].substr(4);
			var name = url.substr(url.lastIndexOf("/") + 1).replace(".git", "");
			return new Git(name, url, branch);
		}
		return null;
	}

	/** installing from github (<User>/<Repository>) */
	@:requirement
	public static function checkGithub(requirement:String):Null<Installable> {
		if (requirement.indexOf("/") >= 0) {
			var parts = requirement.split("#");
			var branch = null;
			if (parts.length > 1)
				branch = parts.pop();
			var url:Path = "https://github.com/" + parts[0] + ".git";
			var name = url.basename();
			return new Git(name, url, branch);
		}
		return null;
	}

	public function isInstalled():Bool {
		var packages = Helm.repository.findPackagesIn(name);
		return packages.length > 0;
	}

	function getCommitId(path:Path):String {
		var cwd = Sys.getCwd();
		Sys.setCwd(path);
		var p = new Process("git", ["rev-parse", "HEAD"]);
		var commitId = p.stdout.readLine();
		p.close();
		Sys.setCwd(cwd);
		return commitId;
	}

	public function install(target:Path, detail:Requirement):Bool {
		Helm.logger.log(L10n.get("installing_package", [name + Config.VERSION_SEP + url]));

		var tmpDir = FileSystem.createTemporary();
		var path = tmpDir;
		var args = ["clone"];
		var branch = this.branch; // for null safety
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
			detail.resolved = url + "#" + getCommitId(target);
			detail.version = info.version;
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
