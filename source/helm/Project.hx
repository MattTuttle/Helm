package helm;

import helm.install.Requirement;
import helm.ds.Lockfile;
import helm.ds.PackageInfo;

class Project {
	public final path:Path;

	public function new() {
		var cwd:Path = Sys.getCwd(); // current working directory
		cwd = cwd.normalize(); // cwd has a nasty habit of including a trailing slash
		this.path = getRoot(cwd);
	}

	public function getRoot(path:Path):Path {
		var search = path;
		while (search != "") {
			if (FileSystem.isFile(search.join("haxelib.json"))) {
				return search;
			}
			search = search.dirname();
		}

		return path;
	}

	public function lockfile():Lockfile {
		var lockfile = Lockfile.load(path);
		if (lockfile == null) {
			lockfile = new Lockfile();
			for (lib in Helm.repository.installed()) {
				var req = Requirement.fromString(lib.name + "@" + lib.version);
				lockfile.addRequirement(req);
			}
		}
		return lockfile;
	}
}
