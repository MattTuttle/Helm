package haxelib;

import haxe.crypto.Md5;
import haxe.io.Bytes;
import helm.ds.Types;
import helm.ds.SemVer;

class HaxelibConnection extends haxe.remoting.Proxy<haxelib.SiteApi> {}

class Haxelib
{

	public var url = "http://lib.haxe.org/";
	public var apiVersion = "3.0";

	public function new()
	{
		_server = new HaxelibConnection(haxe.remoting.HttpConnection.urlConnect(url + "api/" + apiVersion + "/index.n").api);
	}

	public function getProjectInfo(name:String):ProjectInfo
	{
		try
		{
			var data = _server.infos(name);
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

	public function findProject(name:String):List<{ name : String, id : Int }>
	{
		try
		{
			return _server.search(name);
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
			var info = _server.user(username);
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

	public function checkPassword(username:String, password:String):Bool
	{
		try
		{
			return _server.checkPassword(username, Md5.encode(password));
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	public function register(username:String, password:String, email:String, name:String):Bool
	{
		try
		{
			return _server.register(username, Md5.encode(password), email, name);
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	public function submit(name:String, data:Bytes, auth:helm.Auth)
	{
		_server.checkDeveloper(name, auth.username);
		var id = _server.getSubmitId();

		// TODO: separate from haxelib?
		var h = new haxe.Http(url);
		h.onError = function(e) { throw e; };
		h.onData = function(d) { trace(d); }
		h.fileTransfert("file", id, new helm.UploadProgress(data), data.length);
		h.request(true);
		haxe.remoting.HttpConnection.TIMEOUT = 1000;

		// is there a reason we have to submit the username/password AGAIN?!?
		_server.processSubmit(id, auth.username, auth.password);
	}

	private var _server:HaxelibConnection;

}
