package ds;

class PackageInfo
{

	public var name(default, null):String;
	public var version(default, null):SemVer;
	public var packages(default, null):Array<PackageInfo>;
	public var path(default, null):String;

	public var fullName(get, never):String;
	private inline function get_fullName():String { return name + "@" + version; }

	public function new(name, version, packages, path)
	{
		this.name = name;
		this.version = version;
		this.packages = packages;
		this.path = path;
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
	var fullname:String;
	var email:String;
	var projects:Array<String>;
}

typedef VersionInfo = {
	var date:String;
	var name:String;
	var comments:String;
}

typedef ProjectInfo = {
	var name:String;
	var desc:String;
	var website:String;
	var owner:String;
	var license:String;
	var curversion:String;
	var versions:Array<VersionInfo>;
	var tags:List<String>;
}
