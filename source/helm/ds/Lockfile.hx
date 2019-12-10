package helm.ds;

import haxe.ds.StringMap;
import haxe.Json;
import sys.io.File;

typedef LockfileLibraryDef = {
	name:String,
	requirements:Array<String>,
	?version:String,
	?resolved:String,
	?integrity:String,
	?dependencies:Dynamic
}

class LockfileLibrary {
	public final version:SemVer;
	public final resolved:String;
	public final integrity:String;
	public final requirements:Array<Requirement>;
	public final dependencies:StringMap<Requirement>;

	public function new(data:LockfileLibraryDef) {
		requirements = data.requirements.map((x) -> new Requirement(x));
		version = data.version;
		resolved = data.resolved;
		integrity = data.integrity;

		dependencies = new StringMap<Requirement>();
		for (field in Reflect.fields(data.dependencies)) {
			var version:Requirement = Reflect.field(data.dependencies, field);
			dependencies.set(field, version);
		}
	}
}

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

	static public function load(path:Path):Lockfile {
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
