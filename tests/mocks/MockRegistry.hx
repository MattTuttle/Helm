package mocks;

import helm.ds.PackageInfo;
import helm.ds.SemVer;
import helm.ds.Types;
import haxe.io.Bytes;
import helm.registry.Registry;

class MockRegistry implements Registry {
	public function new() {}

	public function getPackageInfo(name:String, version:SemVer):PackageInfo {
		return null;
	}

	public function getProjectInfo(name:String):ProjectInfo {
		return null;
	}

	public function getUserInfo(username:String):UserInfo {
		return null;
	}

	public function register(username:String, password:String, email:String, name:String):Bool {
		return false;
	}

	public function checkPassword(username:String, password:String):Bool {
		return false;
	}

	public function submit(name:String, data:Bytes, auth:helm.Auth):Void {}

	public function search(name:String):Array<String> {
		return [];
	}
}
