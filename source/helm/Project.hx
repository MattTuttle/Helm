package helm;

import helm.install.Requirement;
import helm.ds.Lockfile;
import helm.ds.PackageInfo;

class Project {
	public function new() {}

	public function getRoot(path:Path):Path {
		var search = path;
		while (search != "") {
			if (FileSystem.isFile(search.join(PackageInfo.JSON))) {
				return search;
			}
			search = search.dirname();
		}

		return path;
	}

	public function lockfile(path:Path):Lockfile {
		var projectRoot = Helm.project.getRoot(path);
		var lockfile = Lockfile.load(projectRoot);
		if (lockfile == null) {
			lockfile = new Lockfile();
			for (lib in Helm.repository.installed(path)) {
				var req = Requirement.fromString(lib.name + "@" + lib.version);
				if (req != null) {
					lockfile.addRequirement(req);
				}
			}
		}
		return lockfile;
	}
}
