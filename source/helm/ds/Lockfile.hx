package helm.ds;

import haxe.Json;
import helm.install.Requirement;
import sys.io.File;

class Lockfile {
	static final JSON = "helm.lock";

	final libraries = new Array<Requirement>();

	public function new() {}

	public function addRequirement(requirement:Requirement) {
		libraries.push(requirement);
	}

	static public function loadFromString(json:String):Lockfile {
		var lockfile = new Lockfile();
		var libs:Array<String> = Json.parse(json);
		for (requirement in libs) {
			lockfile.addRequirement(new Requirement(requirement));
		}
		return lockfile;
	}

	static public function load(path:Path):Null<Lockfile> {
		var dataPath = path.join(JSON);
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
			File.saveContent(path.join(JSON), toString());
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}

	public function toString():String {
		return haxe.Json.stringify(libraries, null, "\t");
	}
}
