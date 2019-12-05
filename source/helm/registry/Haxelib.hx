package helm.registry;

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

class Haxelib implements Registry
{
	final url:String;
	final apiVersion:String = "3.0";

	public function new()
	{
		#if cpp
		url = "https://lib.haxe.org/";
		#else
		url = "http://lib.haxe.org/";
		#end
	}

	function call(func:String, params:Array<Dynamic>):Dynamic
	{
		var data = null;
		var h = new haxe.Http(url + "api/" + apiVersion + "/index.n");
		var s = new haxe.Serializer();
		s.serialize(["api", func]);
		s.serialize(params);
		h.setHeader("X-Haxe-Remoting","1");
		h.setParameter("__x",s.toString());
		h.onData = function(d) { data = d; };
		h.onError = function(e) { throw e; };
		h.request(true);
		if( data.substr(0,3) != "hxr" )
			throw "Invalid response : '"+data+"'";
		data = data.substr(3);
		return new haxe.Unserializer(data).unserialize();
	}

	public function getProjectInfo(name:String):ProjectInfo
	{
		try
		{
			var data:ProjectInfos = call("infos", [name]);
			var info:ProjectInfo = {
				name: data.name,
				website: data.website,
				tags: data.tags,
				owner: data.owner,
				description: data.desc,
				currentVersion: data.curversion,
				license: data.license,
				versions: new Array<VersionInfo>()
			};

			var projectUrl = url + "files/" + apiVersion + "/" + data.name + "-";
			for (version in data.versions)
			{
				info.versions.push({
					value: SemVer.ofString(version.name),
					url: projectUrl + version.name.split(".").join(",") + ".zip",
					date: Date.fromString(version.date),
					comments: version.comments
				});
			}
			info.versions.sort(function(a:VersionInfo, b:VersionInfo):Int {
				return a.value > b.value ? -1 : (a.value < b.value ? 1 : 0);
			});
			return info;
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

    public function getUserInfo(username:String):UserInfo
	{
		try
		{
			var info:UserInfos = call("user", [username]);
			return {
				name: info.name,
				fullName: info.fullname,
				projects: info.projects,
				email: info.email
			};
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

    public function register(username:String, password:String, email:String, name:String):Bool
	{
		try
		{
			return call("register", [username, Md5.encode(password), email, name]);
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	public function checkPassword(username:String, password:String):Bool
	{
		try
		{
			return call("checkPassword", [username, Md5.encode(password)]);
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	public function search(word:String):Array<String>
	{
		var result:List<{ id:Int, name:String }> = call("search", [word]);
		return [for (row in result) row.name];
	}

	public function submit(name:String, data:Bytes, auth:helm.Auth):Void
	{
		call("checkDeveloper", [name, auth.username]);
		var id = call("getSubmitId", []);

		var h = new haxe.Http(url);
		h.onError = function(e) { throw e; };
		h.onData = function(d) { trace(d); }
		h.fileTransfer("file", id, new UploadProgress(data), data.length);
		h.request(true);

		call("processSubmit", [id, auth.username, auth.password]);
	}
}
