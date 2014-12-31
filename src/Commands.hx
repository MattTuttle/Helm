import sys.io.File;
import sys.FileSystem;
import tools.haxelib.SemVer;
import tools.haxelib.Data;

using StringTools;

class Commands
{

	@usage("[package [version]]")
	@alias("isntall") // TODO: allow for command aliases
	static public function install(args:Array<String>):Bool
	{
		if (args.length > 2) return false;

		var path = Sys.getCwd();
		for (arg in args)
		{
			switch (arg)
			{
				case "-g":
					path = Repository.globalPath();
					args.remove(arg);
			}
		}

		// TODO: handle cancelled downloads

		if (args.length == 0)
		{
			var libs = Repository.findDependencies(Sys.getCwd());

			// install libraries found
			for (lib in libs.keys())
			{
				Repository.install(lib, libs.get(lib), path);
			}
		}
		else
		{
			var version = args.length > 1 ? SemVer.ofString(args[1]) : null;
			Repository.install(args[0], version, path);
		}

		return true;
	}

	@category("package")
	static public function publish(args:Array<String>):Bool
	{
		return false;
	}

	@category("package")
	static public function list(args:Array<String>):Bool
	{
		var path = Sys.getCwd();
		for (arg in args)
		{
			switch (arg)
			{
				case "-g":
					path = Repository.globalPath();
			}
		}

		Logger.log(path);
		var list = Repository.list(path);
		if (list.length == 0)
		{
			Logger.log("└── (empty)");
		}
		else
		{
			Repository.printPackages(list);
		}
		return true;
	}

	@usage
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

	@usage("package")
	static public function which(args:Array<String>):Bool
	{
		if (args.length < 1) return false;

		var repo = Repository.findPackage(args.shift());
		var info = Repository.loadPackageInfo(repo);
		Logger.log(repo + " [" + info.version + "]");
		return true;
	}

	@usage("package [args ...]")
	static public function run(args:Array<String>):Bool
	{
		if (args.length < 1) return false;

		var name = args.shift();
		var repo = Repository.findPackage(name);
		var run = "run.n";

		// TODO: add ability to run program with haxe command instead of neko

		if (!FileSystem.exists(repo + run))
		{
			throw "Run command not enabled for " + name;
		}

		args.insert(0, run);
		args.push(Sys.getCwd());

		Sys.setCwd(repo);
		Sys.putEnv("HAXELIB_RUN", "1");
		Sys.exit(Sys.command("neko", args));
		return true;
	}

	@category("repository")
	static public function clean(args:Array<String>):Bool
	{
		// FileSystem.deleteDirectory(CACHE_DIR);
		return false;
	}

	@usage("package [package ...]")
	static public function path(args:Array<String>):Bool
	{
		if (args.length < 1) return false;

		for (name in args)
		{
			Repository.printInclude(name);
		}

		return true;
	}

	@usage("package [version]")
	static public function info(args:Array<String>):Bool
	{
		if (args.length < 1 || args.length > 2) return false;

		var info = Repository.instance.infos(args[0]);

		Logger.log(info.name + " [" + info.website + "]");
		Logger.log(info.desc);
		Logger.log();
		Logger.log("   Owner: " + info.owner);
		Logger.log(" License: " + info.license);
		Logger.log("    Tags: " + info.tags.join(", "));
		Logger.log();

		if (args.length == 2)
		{
			var versions = new Array<String>();
			// TODO: error handling if invalid version passed
			var requestedVersion:SemVer = SemVer.ofString(args[1]);
			for (version in info.versions)
			{
				if (SemVer.ofString(version.name) == requestedVersion)
				{
					Logger.log(" Version: " + version.name);
					Logger.log("    Date: " + version.date);
					Logger.log(" Comment: " + version.comments);
					break;
				}
			}
		}
		else
		{
			var versions = new Array<String>();
			for (version in info.versions) { versions.push(version.name); }
			Logger.log("Versions: (current = " + info.curversion + ")");
			Logger.logList(versions, false);
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
		Logger.log(user.fullname + " [" + user.email + "]");
		Logger.log();
		Logger.log("Packages:");
		Logger.logList(user.projects);

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
		Logger.logList(names);

		return true;
	}

}
