package helm.ds;

import sys.io.File;
import helm.ds.Ini.IniSection;
import helm.install.Requirement;

class Lockfile {
	static final FILE = "helm.lock";

	public final requirements:Array<Requirement>;

	public function new(requirements:Array<Requirement>) {
		this.requirements = requirements;
	}

	static public function loadFromString(ini:Ini):Lockfile {
		var requirements = [];
		for (library in ini.keys()) {
			var section = ini.get(library);
			if (section == null)
				continue;
			var req = Requirement.fromString(library.toLowerCase());
			requirements.push(req);
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
		return new Lockfile(requirements);
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

	public function save():Bool {
		try {
			var path = Helm.project.path;
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
			var version = req.version;
			if (version != null)
				section.set('version', version);
			section.set('resolved', req.resolved);
			section.set('integrity', req.integrity);
			ini.set(req.name, section);
		}
		return '; Helm lockfile\n$ini';
	}
}
