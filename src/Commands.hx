import haxe.Http;
import sys.io.File;
import sys.FileSystem;
import tools.haxelib.SemVer;

using StringTools;

class Commands
{

	@:helpText("package [version]")
	static public function install(args:Array<String>):Bool
	{
		if (args.length < 1 || args.length > 2) return false;

		var version = args.length > 1 ? SemVer.ofString(args[1]) : null;
		var info = Repository.instance.infos(args[0]);
		var url = Repository.fileURL(info, version);

		var cachePath = "cache/" + url.split("/").pop();
		// TODO: allow to redownload with --force argument
		if (!FileSystem.exists(cachePath))
		{
			var out = File.write(cachePath, true);
			var progress = new DownloadProgress(out);
			var http = new Http(url);
			http.onError = function(error) {
				progress.close();
			};
			http.customRequest(false, progress);
		}

		var f = File.read(cachePath, true);
		var zip = haxe.zip.Reader.readZip(f);
		f.close();
		var infos = tools.haxelib.Data.readInfos(zip, false);
		var basepath = tools.haxelib.Data.locateBasePath(zip);

		var target = "haxelibs/" + info.name + "/" + version + "/";
		FileSystem.createDirectory(target);

		for (item in zip)
		{
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
					if( path != "" ) trace("  Created "+path);
					continue; // was just a directory
				}
				path += file;
				trace("  Install " + path);
				var data = haxe.zip.Reader.unzip(item);
				File.saveBytes(target + path, data);
			}
		}

		return true;
	}

	@:helpText("package [version]")
	static public function info(args:Array<String>):Bool
	{
		if (args.length < 1 || args.length > 2) return false;

		var info = Repository.instance.infos(args[0]);

		Sys.println(info.name + " [" + info.website + "]");
		Sys.println(info.desc + "\n");
		Sys.println("   Owner: " + info.owner);
		Sys.println(" License: " + info.license);
		Sys.println("    Tags: " + info.tags.join(", "));

		Sys.print("\n");

		if (args.length == 2)
		{
			var versions = new Array<String>();
			// TODO: error handling if invalid version passed
			var requestedVersion:SemVer = SemVer.ofString(args[1]);
			for (version in info.versions)
			{
				if (SemVer.ofString(version.name) == requestedVersion)
				{
					Sys.println(" Version: " + version.name);
					Sys.println("    Date: " + version.date);
					Sys.println(" Comment: " + version.comments);
					break;
				}
			}
		}
		else
		{
			var versions = new Array<String>();
			for (version in info.versions) { versions.push(version.name); }
			Sys.println("Versions: (current = " + info.curversion + ")");
			printStringList(versions, false);
		}

		return true;
	}

	@:helpText("[username] [email]")
	static public function register(args:Array<String>):Bool
	{
		var proxy = Repository.instance;
		var username = "heardtheword";
		var email = "heardtheword@gmail.com";
		var password = "";
		var name = "Matt Tuttle";
		if (proxy.isNewUser(username))
		{
			proxy.register(username, password, email, name);
		}
		return true;
	}

	@:helpText("username")
	static public function user(args:Array<String>):Bool
	{
		if (args.length != 1) return false;

		var user = Repository.instance.user(args[0]);
		Sys.println(user.fullname + " [" + user.email + "]");
		Sys.println("\nPackages:");
		printStringList(user.projects);

		return true;
	}

	@:helpText("package [package ...]")
	static public function search(args:Array<String>):Bool
	{
		if (args.length == 0) return false;

		var names = new Array<String>();

		// for every argument do a search against haxelib repository
		for (arg in args)
		{
			for (result in Repository.instance.search(arg))
			{
				names.push(result.name);
			}
		}

		// print names in columns sorted alphabetically
		printStringList(names);

		return true;
	}

	/**
	 * Prints a string list in multiple columns
	 */
	static private function printStringList(list:Iterable<String>, ascending:Bool = true):Void
	{
		var maxLength = 0, col = 0;
		var array = new Array<String>();
		for (item in list)
		{
			if (item.length > maxLength) maxLength = item.length;
			array.push(item); // copy to array so sorting works...
		}

		maxLength += 2; // add padding

		array.sort(function (a:String, b:String):Int {
			a = a.toLowerCase();
			b = b.toLowerCase();
			if (ascending)
				return (a > b ? 1 : (a < b ? -1 : 0));
			else
				return (a > b ? -1 : (a < b ? 1 : 0));
		});
		for (item in array)
		{
			Sys.print(item.rpad(" ", maxLength));
			col += maxLength;
			if (col > 80)
			{
				Sys.print("\n");
				col = 0;
			}
		}
		if (col > 0) Sys.print("\n"); // add newline, if not at beginning of line
	}

}
