package org.haxe.lib;

/**
 * Haxelib site API
 */

 typedef UserInfos = {
	var name:String;
	var fullname:String;
	var email:String;
	var projects:Array<String>;
}

 typedef VersionInfos = {
	var date:String;
	var name:String;
	var comments:String;
}

typedef ProjectInfos = {
	var name:String;
	var desc:String;
	var website:String;
	var owner:String;
	var license:String;
	var curversion:String;
	var versions:Array<VersionInfos>;
	var tags:List<String>;
}

interface SiteApi
{
	public function search(word:String):List<{ id:Int, name:String }>;
	public function infos(project:String):ProjectInfos;
	public function user(name:String):UserInfos;
	public function register(name:String, pass:String, mail:String, fullname:String):Bool;
	public function isNewUser(name:String):Bool;
	public function checkDeveloper(prj:String, user:String):Void;
	public function checkPassword(user:String, pass:String):Bool;
	public function getSubmitId():String;
	public function processSubmit(id:String, user:String, pass:String):String;
	public function postInstall(project:String, version:String):Void;
}
