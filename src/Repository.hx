import haxe.Http;
import sys.io.File;
import sys.FileSystem;
import tools.haxelib.SemVer;
import tools.haxelib.Data;

using StringTools;

class Repository extends haxe.remoting.Proxy<tools.haxelib.SiteApi>
{

	// TODO: setup a mirror list for multiple repository servers
	static public var LIB_DIR:String = "libs";
	static public var NDLL_DIR:String = "ndll";

	static public var url = "http://lib.haxe.org/";
	static public var apiVersion = "3.0";

	static public var instance(get, never):Repository;
	static private function get_instance():Repository
	{
		return new Repository(haxe.remoting.HttpConnection.urlConnect(url + "api/" + apiVersion + "/index.n").api);
	}

	static public function cachePath():String
	{
		// TODO: make this relative to the haxelib command?
		return "/Users/itmbp/Projects/.other/hxlib/cache/";
	}

	static private function getPackage(path:String):{name:String, dependencies:Array<tools.haxelib.Dependency>}
	{
		if (FileSystem.exists(path + Data.JSON))
		{
			var data = Data.readData(File.getContent(path + Data.JSON), false);
			return {
				name: Std.string(data.name).toLowerCase(),
				dependencies: data.dependencies
			};
		}
		return {
			name: "",
			dependencies: null
		};
	}

	static public function find(name:String, target:String=null):String
	{
		if (target == null) target = Sys.getCwd();

		name = name.toLowerCase();

		// if the name is already in the path, check it first
		var index = target.toLowerCase().lastIndexOf(name);
		if (index != -1)
		{
			var path = target.substr(0, index + name.length) + "/";
			if (getPackage(path).name == name) return path;
		}

		// search in the current directory for a haxelib.json file
		if (getPackage(target).name == name)
		{
			return target;
		}

		// search libs directory
		target += LIB_DIR + "/";
		if (FileSystem.exists(target) && FileSystem.isDirectory(target))
		{
			for (item in FileSystem.readDirectory(target))
			{
				var path = target + item + "/";
				var data = getPackage(path);
				if (data.name == name)
				{
					return path;
				}
				// search subfolders
				if (FileSystem.exists(path + LIB_DIR + "/"))
				{
					var found = find(name, path);
					if (found != null) return found;
				}
			}
		}

		return null;
	}

	static public function print(name:String, target:String=null):Void
	{
		if (target == null) target = find(name);
		else target += LIB_DIR + "/" + name + "/";

		if (target != null && FileSystem.exists(target))
		{
			var lib = target + NDLL_DIR + "/";
			if (FileSystem.exists(lib))
			{
				Sys.println("-L " + lib);
			}
			Sys.println(target);
			Sys.println("-D " + name);
			var data = Data.readData(sys.io.File.getContent(target + Data.JSON), false);
			for (dependency in data.dependencies)
			{
				print(dependency.name, target);
			}
		}
		else
		{
			throw "Package '" + name + "' is not installed.";
		}
	}

	static public function download(name:String, version:SemVer):String
	{
		var info = Repository.instance.infos(name);
		var url = Repository.fileURL(info, version);

		var cache = cachePath() + url.split("/").pop();
		FileSystem.createDirectory(cachePath());
		// TODO: allow to redownload with --force argument
		if (!FileSystem.exists(cache))
		{
			var out = File.write(cache, true);
			var progress = new DownloadProgress(out);
			var http = new Http(url);
			http.onError = function(error) {
				progress.close();
			};
			http.customRequest(false, progress);
		}

		return cache;
	}

	static public function install(name:String, ?version:SemVer, target:String="")
	{
		var path = download(name, version);

		var f = File.read(path, true);
		var zip = haxe.zip.Reader.readZip(f);
		f.close();
		var infos = Data.readInfos(zip, false);
		var basepath = Data.locateBasePath(zip);

		target += LIB_DIR + "/" + name + "/";
		FileSystem.createDirectory(target);

		var totalItems = zip.length,
			unzippedItems = 0;
		for (item in zip)
		{
			var percent = unzippedItems++ / totalItems;
			var progress = StringTools.rpad(StringTools.lpad(">", "-", Math.round(20 * percent)), " ", 20);
			Sys.print("Unpacking [" + progress + "] " + unzippedItems + "/" + totalItems + "\r");

			var name = item.fileName;
			if (name.startsWith(basepath))
			{
				// remove basepath
				name = name.substr(basepath.length, name.length - basepath.length);
				if (name.charAt(0) == "/" || name.charAt(0) == "\\" || name.split("..").length > 1)
					throw "Invalid filename : " + name;
				var dirs = ~/[\/\\]/g.split(name);
				var path = "";
				var file = dirs.pop();
				for (dir in dirs)
				{
					path += dir;
					FileSystem.createDirectory(target + path);
					path += "/";
				}
				if (file == "")
				{
					continue; // was just a directory
				}
				path += file;
				var data = haxe.zip.Reader.unzip(item);
				File.saveBytes(target + path, data);
			}
		}
		var out = "Installed '" + name + "' in " + target;
		Sys.println(out.rpad(" ", 80));

		for (d in infos.dependencies)
		{
			try
			{
				version = SemVer.ofString(d.version);
			}
			catch(e:Dynamic)
			{
				version = null;
			}
			install(d.name, version, target);
		}
	}

	static public function fileURL(info:ProjectInfos, version:SemVer=null):String
	{
		var versionString:String = null;

		if (version == null)
		{
			versionString = SemVer.ofString(info.curversion);
		}
		else
		{
			for (v in info.versions)
			{
				if (SemVer.ofString(v.name) == version)
				{
					versionString = version;
					break;
				}
			}
		}

		if (versionString != null)
		{
			// files stored on server use commas instead of periods
			versionString = versionString.split(".").join(",");

			// TODO: return this information from the server instead of creating it on the client
			return url + "files/" + apiVersion + "/" + info.name + "-" + versionString + ".zip";
		}
		return null;
	}

}
