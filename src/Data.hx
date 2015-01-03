import haxe.Json;
import haxe.zip.Entry;
import haxe.zip.Reader;
import sys.io.File;
import sys.FileSystem;

typedef HaxelibDependency = {
	name:String,
	version:SemVer
}

typedef HaxelibData = {
	name:String,
	license:String,
	description:String,
	contributors:Array<String>,
	releasenote:String,
	url:String,
	dependencies:List<HaxelibDependency>,
	version:SemVer
}

class Data
{

	static public var JSON:String = "haxelib.json";

	static public function readData(json:String):HaxelibData
	{
		var json = Json.parse(json);
		var dependencies = new List<HaxelibDependency>();
		for (field in Reflect.fields(json.dependencies))
		{
			dependencies.add({
				name: field,
				version: SemVer.ofString(Reflect.field(json.dependencies, field))
			});
		}
		return {
			name: json.name,
			license: json.license,
			description: json.description,
			contributors: json.contributors,
			releasenote: json.releasenote,
			url: json.url,
			dependencies: dependencies,
			version: SemVer.ofString(json.version)
		};
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

		return readData(infodata);
	}

}
