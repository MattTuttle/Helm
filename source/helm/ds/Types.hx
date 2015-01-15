package helm.ds;

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
