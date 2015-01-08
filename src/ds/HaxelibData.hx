package ds;

import haxe.Json;
import haxe.ds.StringMap;
import haxe.zip.Entry;
import haxe.zip.Reader;
import sys.io.File;
import sys.FileSystem;

class HaxelibData
{

	static public var JSON:String = "haxelib.json";

	public var name:String;
	public var license:String;
	public var description:String;
	public var contributors:Array<String>;
	public var releasenote:String;
	public var url:String;
	public var dependencies:StringMap<SemVer>;
	public var version:SemVer;

	public function new()
	{
		dependencies = new StringMap<SemVer>();
		contributors = new Array<String>();
	}

	public function read(json:String)
	{
		// TODO: error handling!!
		var json = Json.parse(json);
		dependencies = new StringMap<SemVer>();
		for (field in Reflect.fields(json.dependencies))
		{
			dependencies.set(field, SemVer.ofString(Reflect.field(json.dependencies, field)));
		}
		name = json.name;
		license = json.license;
		description = json.description;
		contributors = json.contributors;
		releasenote = json.releasenote;
		url = json.url;
		version = SemVer.ofString(json.version);
	}

	public function toString():String
	{
		var data = {
			name: name,
			description: description,
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

	public static function locateBasePath(zip:List<Entry>):String {
		for (f in zip)
		{
			if (StringTools.endsWith(f.fileName, JSON))
			{
				return f.fileName.substr(0, f.fileName.length - JSON.length);
			}
		}
		throw "No " + JSON + " found";
	}

	public static function readInfos(zip:List<Entry>):HaxelibData {
		var infodata = null;
		for (f in zip)
		{
			if (StringTools.endsWith(f.fileName, JSON))
			{
				infodata = Reader.unzip(f).toString();
				break;
			}
		}
		if (infodata == null)
			throw JSON + " not found in package";

		var data = new HaxelibData();
		data.read(infodata);
		return data;
	}

}
