package helm.registry;

import helm.ds.PackageInfo;
import helm.ds.SemVer;
import helm.ds.Types;
import haxe.io.Bytes;

interface Registry {
	public function getPackageInfo(name:String, version:SemVer):PackageInfo;
	public function getProjectInfo(name:String):ProjectInfo;
	public function getUserInfo(username:String):UserInfo;
	public function register(username:String, password:String, email:String, name:String):Bool;
	public function checkPassword(username:String, password:String):Bool;
	public function submit(name:String, data:Bytes, auth:helm.Auth):Void;
	public function search(name:String):Array<String>;
}
