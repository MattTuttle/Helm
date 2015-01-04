typedef PackageInfo = {
	name:String,
	version:SemVer,
	packages: Array<PackageInfo>,
	path:String
};

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
