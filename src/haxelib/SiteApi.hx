package haxelib;

import ds.Types;

/**
 * Haxelib site API
 */

interface SiteApi
{
	public function search(word:String):List<{ id:Int, name:String }>;
	public function infos(project:String):ProjectInfo;
	public function user(name:String):UserInfo;
	public function register(name:String, pass:String, mail:String, fullname:String):Bool;
	public function isNewUser(name:String):Bool;
	public function checkDeveloper(prj:String, user:String):Void;
	public function checkPassword(user:String, pass:String):Bool;
	public function getSubmitId():String;
	public function processSubmit(id:String, user:String, pass:String):String;
	public function postInstall(project:String, version:String):Void;
}
