package helm.ds;

import haxe.ds.StringMap;

class PackageInfo
{

	public var name(default, null):String;
	public var version(default, null):SemVer;
	public var dependencies(default, null):StringMap<SemVer>;
	public var path(default, null):String;
	public var mainClass(default, null):String;

	public var fullName(get, never):String;
	private inline function get_fullName():String { return name + "@" + version; }

	public function new(name, version, dependencies, path, mainClass)
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

typedef AuthInfo = {
	var username:String;
	var password:String;
}

typedef UserInfo = {
	var name:String;
	var fullName:String;
	var email:String;
	var projects:Array<String>;
}

typedef VersionInfo = {
	var date:Date;
	var value:SemVer;
	var comments:String;
	var url:String;
}

typedef ProjectInfo = {
	var name:String;
	var description:String;
	var website:String;
	var owner:String;
	var license:String;
	var currentVersion:String;
	var versions:Array<VersionInfo>;
	var tags:List<String>;
}
