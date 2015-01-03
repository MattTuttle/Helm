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

	static public function readData(path:String):HaxelibData
	{
		if (!FileSystem.exists(path)) return null;
		var content = Json.parse(File.getContent(path));
		return {
			name: content.name,
			license: content.license,
			description: content.description,
			contributors: content.contributors,
			releasenote: content.releasenote,
			url: content.url,
			dependencies: content.dependencies,
			version: SemVer.ofString(content.version)
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
