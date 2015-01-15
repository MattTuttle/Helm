package helm.ds;

import haxe.ds.StringMap;

class PackageInfo
{

	public var name(default, null):String;
	public var version(default, null):SemVer;
	public var dependencies(default, null):StringMap<String>;
	public var path(default, null):String;
	public var mainClass(default, null):String;

	public var fullName(get, never):String;
	private inline function get_fullName():String { return name + "@" + version; }

	public function new(name:String, version:String, dependencies:StringMap<String>, path:String, mainClass:String)
	{
		this.name = name;
		this.version = version;
		this.dependencies = dependencies;
		this.path = path;
		this.mainClass = mainClass;
	}

	public function toString():String
	{
		return name;
	}

}
