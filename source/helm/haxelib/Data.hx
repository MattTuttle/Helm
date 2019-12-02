package helm.haxelib;

import haxe.Json;
import haxe.ds.StringMap;
import haxe.zip.Entry;
import haxe.zip.Reader;
import sys.io.File;
import sys.FileSystem;
import helm.ds.SemVer;
import helm.Helm;
import helm.util.*;

class Data
{

	static public var JSON:String = "haxelib.json";

	public var name:String = "";
	public var license:String = "";
	public var description:String = "";
	public var classPath:String = "";
	public var contributors:Array<String>;
	public var releasenote:String = "";
	public var mainClass:String = "";
	public var url:String = "";
	public var dependencies:StringMap<String>;
	public var version:SemVer;

	public function new()
	{
		dependencies = new StringMap<String>();
		contributors = new Array<String>();
	}

	public function read(json:String)
	{
		// TODO: error handling!!
		var json = Json.parse(json);
		for (field in Reflect.fields(json.dependencies))
		{
			var version:String = Reflect.field(json.dependencies, field);
			dependencies.set(field, version);
		}
		name = json.name;
		license = json.license;
		classPath = json.classPath;
		description = json.description;
		contributors = json.contributors;
		releasenote = json.releasenote;
		mainClass = json.main;
		url = json.url;
		version = SemVer.ofString(json.version);
	}

	public function toString():String
	{
		var deps = new StringMap<String>();
		for (dep in dependencies.keys())
		{
			deps.set(dep, dependencies.get(dep).toString());
		}
		var data = {
			name: name,
			description: description,
			classPath: classPath,
			version: version.toString(),
			license: license,
			releasenote: releasenote,
			url: url,
			contributors: contributors,
			dependencies: deps
		};
		var json = haxe.Json.stringify(data, null, "\t");
		return json;
	}

	static public function init(path:Path, logger:Logger)
	{
		var data = new Data();

		// fill in dependencies
		for (dep in Helm.repository.list(path))
		{
			data.dependencies.set(dep.name, dep.version);
		}

		// data.dependencies
		data.name = logger.prompt(L10n.get("init_project_name"), path.dirname());
		data.description = logger.prompt(L10n.get("init_project_description"));
		data.version = logger.prompt(L10n.get("init_project_version"), "0.1.0");
		data.url = logger.prompt(L10n.get("init_project_url"));
		data.license = logger.prompt(L10n.get("init_project_license"), "MIT");

		var out = sys.io.File.write(Data.JSON);
		out.writeString(data.toString());
		out.close();
	}

}
