package org.haxe.lib;

import haxe.crypto.Md5;
import haxe.io.Bytes;
import helm.ds.Types;
import helm.ds.SemVer;
import helm.Directory;
import helm.http.UploadProgress;

#if haxelib

class Haxelib
{

	public var url = "http://lib.haxe.org/";
	public var apiVersion = "3.0";

	public function new()
	{
		_server = new Connection();
	}

	public static var path(get, never):String;
	private static function get_path():String
	{
		var path = Sys.getEnv("HAXELIB_PATH");
		if (path == null)
		{
			var home = Directory.homeDir;
			if (sys.FileSystem.exists(home + Directory.SEPARATOR + ".haxelib"))
			{
				path = sys.io.File.getContent(home + Directory.SEPARATOR + ".haxelib");
			}
			else if (sys.FileSystem.exists("/etc/haxelib"))
			{
				path = sys.io.File.getContent("/etc/haxelib");
			}
			else
			{
				path = "/usr/local/lib/haxe/";
			}
		}

		// make sure the path ends with a slash
		if (!StringTools.endsWith(path, Directory.SEPARATOR))
		{
			path += Directory.SEPARATOR;
		}

		if (!(sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path)))
		{
			throw "Invalid package directory " + path;
		}
		return path;
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
		h.fileTransfer("file", id, new UploadProgress(data), data.length);
		h.request(true);
		haxe.remoting.HttpConnection.TIMEOUT = 1000;

		// is there a reason we have to submit the username/password AGAIN?!?
		_server.processSubmit(id, auth.username, auth.password);
	}

	private var _server:Connection;

}

#end
