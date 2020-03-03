package helm.ds;

import sys.io.File;
import helm.ds.Ini.IniSection;
import helm.install.Requirement;

class Lockfile {
	static final FILE = "helm.lock";

	final requirements = new Array<Requirement>();

	public function new() {}

	public function addRequirement(requirement:Requirement) {
		requirements.push(requirement);
	}

	static public function loadFromString(ini:Ini):Lockfile {
		var lockfile = new Lockfile();
		for (library in ini.keys()) {
			var section = ini.get(library);
			var req = new Requirement(library.toLowerCase());
			lockfile.addRequirement(req);
			for (key in section.keys()) {
				var value = section.get(key);
				switch (key) {
					case "version":
						req.version = value;
					case "resolved":
						req.resolved = value;
					case "integrity":
						req.integrity = value;
				}
			}
		}
		return lockfile;
	}

	static public function load(path:Path):Null<Lockfile> {
		var dataPath = path.join(FILE);
		if (FileSystem.isFile(dataPath)) {
			try {
				var data = File.getContent(dataPath);
				return loadFromString(data);
			} catch (e:Dynamic) {
				// do nothing?
			}
		}
		return null;
	}

	public function save(path:Path):Bool {
		try {
			File.saveContent(path.join(FILE), toString());
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}

	public function toString():String {
		var ini = new Ini();
		for (req in requirements) {
			var section = new IniSection();
			section.set('version', req.version);
			section.set('resolved', req.resolved);
			section.set('integrity', req.integrity);
			ini.set(req.name, section);
		}
		return ini;
	}
}
