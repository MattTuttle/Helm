package helm.ds;

import haxe.ds.StringMap;
import haxe.Json;
import sys.io.File;

typedef Requirement = String;

typedef LockfileLibraryDef = {
	name:String,
	requirements:Array<String>,
	version:String,
	resolved:String,
	integrity:String,
	?dependencies:Dynamic
}

class LockfileLibrary {
	public final version:SemVer;
	public final resolved:String;
	public final integrity:String;
	public final requirements:Array<Requirement>;
	public final dependencies:StringMap<Requirement>;

	public function new(data:LockfileLibraryDef) {
		requirements = data.requirements;
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

	public final libraries:Array<LockfileLibrary>;

	function new(libs:Array<LockfileLibraryDef>) {
		libraries = [];
		for (libdef in libs) {
			libraries.push(new LockfileLibrary(libdef));
		}
	}

	static public function loadFromString(json:String):Lockfile {
		return new Lockfile(Json.parse(json));
	}

	static public function load(path:Path):Lockfile {
		var dataPath = path.join(JSON);
		if (FileSystem.isFile(dataPath)) {
			try {
				var data = File.getContent(dataPath);
				var json = Json.parse(data);
				var info = new Lockfile(json);
				return info;
			} catch (e:Dynamic) {
				// do nothing?
			}
		}
		return null;
	}
}
