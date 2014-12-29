import sys.io.File;
import sys.FileSystem;
import tools.haxelib.SemVer;
import tools.haxelib.Data;

using StringTools;

class Commands
{

	@usage("[package [version]]")
	static public function install(args:Array<String>):Bool
	{
		if (args.length > 2) return false;

		if (args.length == 0)
		{
			for (item in FileSystem.readDirectory("."))
			{
				// search hxml file for libraries to install
				if (item.endsWith("hxml"))
				{
					var hxml = File.getContent(item);
					for (line in hxml.split("\n"))
					{
						if (line.startsWith("-lib"))
						{
							var lib = line.split(" ").pop();
							Repository.install(lib);
						}
					}
				}
				else if (item.endsWith("json"))
				{
					var data = Data.readData(item, false);
					trace(data);
				}
			}
		}
		else
		{
			var version = args.length > 1 ? SemVer.ofString(args[1]) : null;
			Repository.install(args[0], version);
		}

		return true;
	}

	@usage("")
	static public function submit(args:Array<String>):Bool
	{
		return false;
	}

	@usage("[name license author version]")
	static public function init(args:Array<String>):Bool
	{
		var data = Data.readData(Data.JSON, false);
		data.name = ProjectName.ofString("");
		var json = haxe.Json.stringify(data);
		// beautify json
		json = json.replace(',', ',\n\t').replace('{', '{\n\t').replace('}', '\n}');
		var out = sys.io.File.write(Data.JSON);
		out.writeString(json);
		out.close();
		return true;
	}

	@usage("package [args ...]")
	static public function run(args:Array<String>):Bool
	{
		if (args.length < 1) return false;

		var command = args.shift();
		var run = Repository.find(command) + "run.n";

		args.insert(0, Sys.getCwd());
		args.insert(0, run);
		// Sys.setCwd(vdir);
		Sys.putEnv("HAXELIB_RUN", "1");
		Sys.command("neko", args);

		return true;
	}

	@category("repository")
	static public function clean(args:Array<String>):Bool
	{
		// FileSystem.deleteDirectory(CACHE_DIR);
		return true;
	}

	@usage("package [package ...]")
	static public function path(args:Array<String>):Bool
	{
		if (args.length < 1) return false;

		for (name in args)
		{
			Repository.print(name);
		}

		return true;
	}

	@usage("package [version]")
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

	@usage("[username] [email]")
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

	@usage("username")
	static public function user(args:Array<String>):Bool
	{
		if (args.length != 1) return false;

		var user = Repository.instance.user(args[0]);
		Sys.println(user.fullname + " [" + user.email + "]");
		Sys.println("\nPackages:");
		printStringList(user.projects);

		return true;
	}

	@usage("package [package ...]")
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
			col += maxLength;
			if (col > 80)
			{
				Sys.print("\n");
				col = 0;
			}
			Sys.print(item.rpad(" ", maxLength));
		}
		if (col > 0) Sys.print("\n"); // add newline, if not at beginning of line
	}

}
