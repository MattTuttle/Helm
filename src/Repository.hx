import haxe.Http;
import haxe.ds.StringMap;
import sys.io.File;
import sys.FileSystem;
import tools.haxelib.SemVer;
import tools.haxelib.Data;

using StringTools;

typedef Package = {
	name:String,
	version:SemVer,
	packages: Array<Package>
};

class Repository extends haxe.remoting.Proxy<tools.haxelib.SiteApi>
{

	// TODO: setup a mirror list for multiple repository servers
	static public var LIB_DIR:String = "libs";
	static public var NDLL_DIR:String = "ndll";

	static public var url = "http://lib.haxe.org/";
	static public var apiVersion = "3.0";

	static public var instance(get, never):Repository;
	@:access(haxe.remoting.HttpConnection)
	static private function get_instance():Repository
	{
		var connection = new haxe.remoting.HttpConnection(url + "api/" + apiVersion + "/index.n", []);
		return new Repository(connection.api);
	}

	static public function cachePath():String
	{
		return globalPath() + "cache/";
	}

	static public function globalPath():String
	{
		// TODO: make this relative to the haxelib command?
		return "/usr/local/lib/haxe/";
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

	static public function findPackage(name:String):String
	{
		var repo = Repository.findPackageIn(name, Sys.getCwd());
		if (repo == null)
		{
			repo = Repository.findPackageIn(name, Repository.globalPath());
			if (repo == null)
				throw "Package " + name + " is not installed";
		}
		return repo;
	}

	static private function findPackageIn(name:String, target:String):String
	{
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
					var found = findPackageIn(name, path);
					if (found != null) return found;
				}
			}
		}

		return null;
	}

	static public function printPackages(list:Array<Package>, ?level:Array<Bool>):Void
	{
		if (level == null) level = [true];

		var numItems = list.length, i = 0;
		for (item in list)
		{
			i += 1;
			var start = "";
			level[level.length - 1] = (i == numItems);
			for (j in 0...level.length - 1)
			{
				start += (level[j] ? "  " : "│ ");
			}
			var hasChildren = item.packages.length > 0;
			var separator = (i == numItems ? "└" : "├") + (hasChildren ? "─┬ " : "── ");
			Logger.log(start + separator + item.name + "@" + item.version);

			if (hasChildren)
			{
				level.push(true);
				printPackages(item.packages, level);
				level.pop();
			}
		}
	}

	static public function list(dir:String):Array<Package>
	{
		var packages = new Array<Package>();
		var libs = dir + LIB_DIR + "/";
		if (FileSystem.exists(libs) && FileSystem.isDirectory(libs))
		{
			for (item in FileSystem.readDirectory(libs))
			{
				var path = libs + item + "/";
				if (FileSystem.exists(path + Data.JSON))
				{
					var data = Data.readData(File.getContent(path + Data.JSON), false);
					packages.push({
						name: data.name,
						version: data.version,
						packages: list(path)
					});
				}
			}
		}
		return packages;
	}

	/**
	 * Returns a list of project dependencies based on files found in the directory
	 */
	static public function findDependencies(dir:String):StringMap<SemVer>
	{
		var libs = new StringMap<SemVer>();
		for (item in FileSystem.readDirectory(dir))
		{
			// search files for libraries to install
			if (item.endsWith("hxml"))
			{
				for (line in File.getContent(item).split("\n"))
				{
					if (line.startsWith("-lib"))
					{
						var lib = line.split(" ").pop().split("=");
						libs.set(lib[0], lib.length > 1 ? SemVer.ofString(lib[1]) : null);
					}
				}
			}
			else if (item.endsWith("json"))
			{
				var data = Data.readData(File.getContent(item), false);
				for (lib in data.dependencies)
				{
					libs.set(lib.name, lib.version != "" ? SemVer.ofString(lib.version) : null);
				}
			}
		}
		return libs;
	}

	static public function print(name:String, target:String=null):Void
	{
		if (target == null) target = findPackageIn(name, Sys.getCwd());
		else target += LIB_DIR + "/" + name + "/";

		if (target != null && FileSystem.exists(target))
		{
			var lib = target + NDLL_DIR + "/";
			if (FileSystem.exists(lib))
			{
				Logger.log("-L " + lib);
			}
			Logger.log(target);
			Logger.log("-D " + name);
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
			Logger.log("Unpacking [" + progress + "] " + unzippedItems + "/" + totalItems + "\r", false);

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
		Logger.log("Installed '" + name + "' in " + target);

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
