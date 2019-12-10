package helm.install;

import helm.ds.PackageInfo;
import helm.ds.SemVer;

using StringTools;

class Requirement {
	public var name(default, null):String;
	public var version:SemVer;
	public var resolved:String;
	public var integrity:String;
	public var dependencies:Array<String>;

	var installable:Installable;

	var original:String;

	public function new(requirement:String) {
		original = requirement;
		var checkFuncs = [checkFilePath, checkGit, checkGithub, checkHaxelib];
		for (func in checkFuncs) {
			func(requirement);
			if (name != null && installable != null) {
				break;
			}
		}
		if (name == null) {
			name = requirement;
		}
		if (installable == null) {
			installable = new Haxelib();
		}
	}

	public function install(target:Path):Bool {
		return installable.install(target, this);
	}

	// installing from a path (C:\User\mypackage)
	function checkFilePath(requirement:String) {
		if (FileSystem.isDirectory(requirement)) {
			var info = PackageInfo.load(requirement);
			if (info != null) {
				name = info.name;
				installable = new FilePath(requirement);
			}
		}
	}

	// installing from a git url (git+http://mygitserver.com/repo.git)
	function checkGit(requirement:String) {
		if (requirement.startsWith("git+")) {
			var parts = requirement.split("#");
			var branch = null;
			if (parts.length > 1)
				branch = parts.pop();
			var url = parts[0].substr(4);
			name = url.substr(url.lastIndexOf("/") + 1).replace(".git", "");
			installable = new Git(url, branch);
		}
	}

	// installing from github (<User>/<Repository>)
	function checkGithub(requirement:String) {
		if (requirement.indexOf("/") >= 0) {
			var parts = requirement.split("#");
			var branch = null;
			if (parts.length > 1)
				branch = parts.pop();
			var url = "https://github.com/" + parts[0] + ".git";
			name = parts[0].split("/").pop();
			installable = new Git(url, branch);
		}
	}

	// installing from haxelib
	function checkHaxelib(requirement:String) {
		// try to split from name:version
		if (requirement.indexOf(":") >= 0) {
			var parts = requirement.split(":");
			if (parts.length == 2) {
				version = SemVer.ofString(parts[1]);
				// only use the first part if successfully parsing a version from the second part
				if (version != null) {
					name = parts[0];
					installable = new Haxelib(version);
				}
			}
		}
	}

	function toString():String {
		return name + ":" + version.toString();
	}
}
