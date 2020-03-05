package helm.ds;

import haxe.Json;
import sys.io.File;
import haxe.ds.StringMap;
import helm.util.Logger;
import helm.util.L10n;

class DependencyIterator {
	var it:Iterator<String>;
	var map:StringMap<String>;

	public function new(dependencies:StringMap<String>) {
		it = dependencies.keys();
		map = dependencies;
	}

	public inline function hasNext():Bool {
		return it.hasNext();
	}

	public function next():String {
		var key = it.next();
		var require = map.get(key);
		// if the requirement is a version or empty, include the name
		if (require == "" || require == null) {
			return key;
		} else if (SemVer.ofString(require) != null) {
			return key + ":" + require;
		}
		return require;
	}
}

@:forward(set)
abstract Dependencies(StringMap<String>) from StringMap<String> to StringMap<String> {
	public function iterator():DependencyIterator {
		return new DependencyIterator(this);
	}
}

class PackageInfo {
	static public var JSON:String = "haxelib.json";

	public final name:String;
	public final license:String;
	public final description:String;
	public final classPath:String;
	public final contributors:Array<String>;
	public final releasenote:String;
	public final mainClass:String;
	public final url:String;
	public final version:SemVer;
	public final dependencies:Dependencies;
	public var filePath(default, null):Path = "";

	public var fullName(get, never):String;

	private inline function get_fullName():String {
		return name + ":" + version;
	}

	// TODO: change dynamic to a typedef
	function new(data:Dynamic) {
		dependencies = new StringMap<String>();
		for (field in Reflect.fields(data.dependencies)) {
			var version:String = Reflect.field(data.dependencies, field);
			dependencies.set(field, version);
		}
		name = data.name;
		license = data.license;
		classPath = data.classPath;
		description = data.description;
		contributors = data.contributors;
		releasenote = data.releasenote;
		mainClass = data.main;
		url = data.url;
		version = SemVer.ofString(data.version);
	}

	static public function loadFromString(json:String):PackageInfo {
		return new PackageInfo(Json.parse(json));
	}

	static public function load(path:Path):Null<PackageInfo> {
		var dataPath = path.join(JSON);
		if (FileSystem.isFile(dataPath)) {
			try {
				var data = File.getContent(dataPath);
				var json = Json.parse(data);
				var info = new PackageInfo(json);
				info.filePath = dataPath;
				return info;
			} catch (e:Dynamic) {
				// do nothing?
			}
		}
		return null;
	}

	public function addDependency(name:String, version:String) {
		dependencies.set(name, version);
	}

	public function save(path:Path):Bool {
		try {
			File.saveContent(path, toString());
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}

	public function toString():String {
		var data = {
			name: name,
			description: description,
			classPath: classPath,
			version: version.toString(),
			license: license,
			releasenote: releasenote,
			url: url,
			contributors: contributors,
			dependencies: dependencies
		};
		var json = haxe.Json.stringify(data, null, "\t");
		return json;
	}

	static public function init(path:Path, logger:Logger) {
		// fill in dependencies
		var dependencies = new StringMap<String>();
		for (dep in Helm.repository.installed()) {
			dependencies.set(dep.name, dep.version);
		}

		var info = new PackageInfo({
			name: logger.prompt(L10n.get("init_project_name"), path.basename()),
			description: logger.prompt(L10n.get("init_project_description")),
			version: logger.prompt(L10n.get("init_project_version"), "0.1.0"),
			url: logger.prompt(L10n.get("init_project_url")),
			license: logger.prompt(L10n.get("init_project_license"), "MIT"),
			dependencies: dependencies
		});
		var path:Path = Sys.getCwd();
		info.filePath = path.join(JSON);
		var out = sys.io.File.write(info.filePath);
		out.writeString(info.toString());
		out.close();
	}
}
