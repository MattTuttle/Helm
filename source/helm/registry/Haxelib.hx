package helm.registry;

import helm.util.L10n;
import helm.ds.PackageInfo;
import sys.Http;
import helm.ds.SemVer;
import helm.ds.Types.UserInfo;
import helm.ds.Types.ProjectInfo;
import helm.ds.Types.VersionInfo;
import haxe.crypto.Md5;
import helm.http.UploadProgress;
import haxe.io.Bytes;

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

class Haxelib implements Registry {
	final url:String;
	final apiVersion:String = "3.0";

	public function new() {
		#if cpp
		url = "https://lib.haxe.org/";
		#else
		url = "http://lib.haxe.org/";
		#end
	}

	function call(func:String, params:Array<Dynamic>):Dynamic {
		var data = "";
		var h = new Http(url + "api/" + apiVersion + "/index.n");
		var s = new haxe.Serializer();
		s.serialize(["api", func]);
		s.serialize(params);
		h.setHeader("X-Haxe-Remoting", "1");
		h.setParameter("__x", s.toString());
		h.onData = (d) -> data = d;
		h.onError = (e) -> throw e;
		h.request(true);
		if (data.substr(0, 3) != "hxr")
			throw "Invalid response : '" + data + "'";
		data = data.substr(3);
		return new haxe.Unserializer(data).unserialize();
	}

	public function getPackageInfo(name:String, version:SemVer):PackageInfo {
		var data = "";
		// TODO: what about haxelib.json files that aren't in the base directory? Is that still a thing??
		var h = new Http(url + "/p/" + name + "/" + version.toString() + "/raw-files/haxelib.json");
		h.onData = (d) -> data = d;
		h.onError = (e) -> throw e;
		h.request(true);
		return PackageInfo.loadFromString(data);
	}

	function sortVersionInfo(a:VersionInfo, b:VersionInfo):Int {
		return a.value > b.value ? -1 : (a.value < b.value ? 1 : 0);
	}

	public function getProjectInfo(name:String):Null<ProjectInfo> {
		try {
			var data:ProjectInfos = call("infos", [name]);
			var info:ProjectInfo = {
				name: data.name,
				website: data.website,
				tags: data.tags,
				owner: data.owner,
				description: data.desc,
				currentVersion: data.curversion,
				license: data.license,
				versions: []
			};

			var projectUrl = url + "files/" + apiVersion + "/" + data.name + "-";
			for (version in data.versions) {
				info.versions.push({
					value: SemVer.ofString(version.name),
					url: projectUrl + version.name.split(".").join(",") + ".zip",
					date: Date.fromString(version.date),
					comments: version.comments
				});
			}
			info.versions.sort(sortVersionInfo);
			return info;
		} catch (e:Dynamic) {
			return null;
		}
	}

	public function getUserInfo(username:String):Null<UserInfo> {
		try {
			var info:UserInfos = call("user", [username]);
			return {
				name: info.name,
				fullName: info.fullname,
				projects: info.projects,
				email: info.email
			};
		} catch (e:Dynamic) {
			return null;
		}
	}

	public function register(username:String, password:String, email:String, name:String):Bool {
		try {
			return call("register", [username, Md5.encode(password), email, name]);
		} catch (e:Dynamic) {
			return false;
		}
	}

	public function checkPassword(username:String, password:String):Bool {
		try {
			return call("checkPassword", [username, Md5.encode(password)]);
		} catch (e:Dynamic) {
			return false;
		}
	}

	public function search(word:String):Array<String> {
		var result:List<{id:Int, name:String}> = call("search", [word]);
		return [for (row in result) row.name];
	}

	public function submit(name:String, data:Bytes, auth:helm.Auth):Void {
		var user = auth.username, pass = auth.password;
		if (user == null || pass == null) {
			Helm.logger.log(L10n.get("not_logged_in"));
		} else {
			call("checkDeveloper", [name, user]);
			var id = call("getSubmitId", []);

			var h = new Http(url);
			h.onData = (d) -> trace(d);
			h.onError = (e) -> throw e;
			h.fileTransfer("file", id, new UploadProgress(data), data.length);
			h.request(true);

			call("processSubmit", [id, user, pass]);
		}
	}
}
