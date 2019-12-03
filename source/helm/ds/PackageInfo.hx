package helm.ds;

import haxe.ds.StringMap;
import helm.haxelib.Data;

class PackageInfo
{

	public var name(default, null):String;
	public var version(default, null):SemVer;
	public var dependencies(default, null):StringMap<String>;
	public var path(default, null):String;
	public var classPath(default, null):String = "";
	public var mainClass(default, null):String;

	public var fullName(get, never):String;
	private inline function get_fullName():String { return name + ":" + version; }

	public function new(name:String, version:String, dependencies:StringMap<String>, path:String, classPath:Path, mainClass:String)
	{
		this.name = name;
		this.version = version;
		this.dependencies = dependencies;
		this.path = path;
		this.classPath = classPath;
		this.mainClass = mainClass;
	}

	static public function load(path:Path):PackageInfo
	{
		var dataPath = path.join(Data.JSON);
		if (FileSystem.isFile(dataPath))
		{
			var data = new Data();
			data.read(dataPath);
			return new PackageInfo(Std.string(data.name).toLowerCase(),
				SemVer.ofString(data.version), data.dependencies, path, data.classPath, data.mainClass);
		}
		return null;
	}

	public function toString():String
	{
		return name;
	}

}
