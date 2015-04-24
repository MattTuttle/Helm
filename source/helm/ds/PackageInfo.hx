package helm.ds;

import haxe.ds.StringMap;

class PackageInfo
{

	static public var JSON = "hxpm.json";

	public var name(default, null):String;
	public var version(default, null):SemVer;
	public var dependencies(default, null):StringMap<String>;
	public var path(default, null):String;
	public var classPath(default, null):String = "";
	public var mainClass(default, null):String;

	public var fullName(get, never):String;
	private inline function get_fullName():String { return name + "@" + version; }

	public function new(name:String, version:String, dependencies:StringMap<String>, path:String, classPath:String, mainClass:String)
	{
		this.name = name;
		this.version = version;
		this.dependencies = dependencies;
		this.path = path;
		if (classPath != null)
		{
			this.classPath = classPath;
			if (!StringTools.endsWith(classPath, Directory.SEPARATOR))
			{
				this.classPath += Directory.SEPARATOR;
			}
		}
		this.mainClass = mainClass;
	}

	static public function load(path:String):PackageInfo
	{
		if (sys.FileSystem.exists(path + org.haxe.lib.Data.JSON))
		{
			var data = new org.haxe.lib.Data();
			data.read(sys.io.File.getContent(path + org.haxe.lib.Data.JSON));
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
