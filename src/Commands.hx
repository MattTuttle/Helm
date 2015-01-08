import sys.io.File;
import sys.FileSystem;
import ds.SemVer;
import ds.HaxelibData;
import ds.Types;

using StringTools;

class Commands
{

	static inline private function getPathTarget():String
	{
		if (Config.useGlobal)
		{
			return Config.globalPath;
		}
		else
		{
			var path = Repository.getPackageRoot(Sys.getCwd(), "haxelib.json");
			return path == null ? Sys.getCwd() : path;
		}
	}

	@usage("[package [version]]")
	@alias("i", "isntall")
	@category("development")
	static public function install(args:Array<String>):Bool
	{
		if (args.length > 2) return false;

		var path = getPathTarget();

		// if no packages are given as arguments, search in local directory for dependencies
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

	@category("development")
	static public function outdated(args:Array<String>):Bool
	{
		var outdated = Repository.outdated(getPathTarget());
		for (item in outdated)
		{
			Logger.log(item.name + "@" + item.current + " < " + item.latest);
		}
		return true;
	}

	@category("development")
	@alias("up", "update")
	static public function upgrade(args:Array<String>):Bool
	{
		var path = getPathTarget();
		var outdated = Repository.outdated(path);
		for (item in outdated)
		{
			Repository.install(item.name, item.latest, path);
		}
		return true;
	}

	@category("information")
	@alias("l", "ls")
	static public function list(args:Array<String>):Bool
	{
		var path = getPathTarget();

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

	@category("development")
	static public function init(args:Array<String>):Bool
	{
		// TODO: make this interactive and less crappy...
		var path = getPathTarget();
		var info = Repository.loadPackageInfo(path);
		if (info != null) throw "Package " + info.fullName + " already exists!";

		var data = new HaxelibData();
		data.name = Logger.prompt(L10n.get("init_project_name"));
		data.description = Logger.prompt("Description: ");
		data.version = Logger.prompt("Version: ", "0.1.0");
		data.url = Logger.prompt("URL: ");
		data.license = Logger.prompt("License: ", "MIT");

		var out = sys.io.File.write(HaxelibData.JSON);
		out.writeString(data.toString());
		out.close();

		return true;
	}

	@usage("package")
	@category("information")
	static public function which(args:Array<String>):Bool
	{
		if (args.length < 1) return false;

		var repo = Repository.findPackage(args.shift());
		var info = Repository.loadPackageInfo(repo);
		Logger.log(repo + " [" + info.version + "]");
		return true;
	}

	@usage("package [args ...]")
	@category("development")
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

		// TODO: Use a flag to set the run path as an environment variable instead of the old way
		if (false)
		{
			Sys.putEnv("HAXELIB_RUN", Sys.getCwd());
		}
		else
		{
			args.push(Sys.getCwd());
			Sys.putEnv("HAXELIB_RUN", "1");
		}

		Sys.setCwd(repo);
		Sys.exit(Sys.command("neko", args));
		return true;
	}

	@category("development")
	@alias("rm", "remove")
	static public function uninstall(args:Array<String>):Bool
	{
		var path = getPathTarget();

		for (arg in args)
		{
			var infos = Repository.findPackageIn(arg, path);
			if (infos.length > 0)
			{
				path = null;
				// TODO: should this only delete from the immediate libs folder instead of searching for a package and accidentally deleting a dependency?
				for (info in infos)
				{
					if (path == null || info.path.length < path.length)
					{
						path = info.path;
					}
				}
				Directory.delete(path);
				Logger.log("Removed " + arg);
			}
		}
		return true;
	}

	@category("misc")
	static public function clean(args:Array<String>):Bool
	{
		var result = Logger.prompt("Are you sure you want to delete the cache? [y/N] ");
		if (~/^y(es)?$/.match(result.toLowerCase()))
		{
			Directory.delete(Config.cachePath);
			Logger.log("Cleared cache");
		}
		return true;
	}

	@usage("package [package ...]")
	@category("information")
	@alias("path")
	static public function include(args:Array<String>):Bool
	{
		if (args.length < 1) return false;

		for (name in args)
		{
			Repository.printInclude(name);
		}

		return true;
	}

	@usage("package [version]")
	@category("information")
	static public function info(args:Array<String>):Bool
	{
		if (args.length == 0)
		{
			var path = Repository.getPackageRoot(Sys.getCwd(), HaxelibData.JSON);
			var info = Repository.loadPackageInfo(path);
			if (info == null)
			{
				Logger.log("Not a helm package");
			}
			else
			{
				Logger.log(info.fullName);
			}
		}
		else
		{
			for (arg in args)
			{
				var parts = arg.split("@");
				var info = Repository.server.infos(parts[0]);

				Logger.log(info.name + " [" + info.website + "]");
				Logger.log(info.desc);
				Logger.log();
				Logger.log("   Owner: " + info.owner);
				Logger.log(" License: " + info.license);
				Logger.log("    Tags: " + info.tags.join(", "));
				Logger.log();

				if (parts.length == 2)
				{
					var versions = new Array<String>();
					// TODO: error handling if invalid version passed or if no version is found
					var requestedVersion:SemVer = SemVer.ofString(parts[1]);
					var found = false;
					for (version in info.versions)
					{
						if (SemVer.ofString(version.name) == requestedVersion)
						{
							Logger.log(" Version: " + version.name);
							Logger.log("    Date: " + version.date);
							Logger.log(" Comment: " + version.comments);
							found = true;
							break;
						}
					}
					if (!found) Logger.log("Version " + requestedVersion + " not found");
				}
				else
				{
					var versions = new Array<String>();
					for (version in info.versions) { versions.push(version.name); }
					Logger.log("Versions: (current = " + info.curversion + ")");
					Logger.logList(versions, false);
				}
				Logger.log("-----------");
			}
		}

		return true;
	}

	@category("development")
	@alias("package")
	static public function bundle(args:Array<String>):Bool
	{
		var path = getPathTarget();
		Bundle.make(path);
		return true;
	}

	@category("development")
	@alias("upload", "submit")
	static public function publish(args:Array<String>):Bool
	{
		var path = getPathTarget();
		var info = Repository.loadPackageInfo(path);

		var auth = new Auth();
		auth.login();
		Repository.server.checkDeveloper(info.name, auth.username);
		var bundleName = Bundle.make(path);

		var zip = File.read(bundleName);
		var data = zip.readAll();

		Repository.submit(data, auth);

		return true;
	}

	@usage("[username] [email]")
	@category("profile")
	static public function register(args:Array<String>):Bool
	{
		var auth = new Auth();
		auth.register();
		return true;
	}

	@usage("username")
	@category("profile")
	static public function user(args:Array<String>):Bool
	{
		if (args.length != 1) return false;

		var user = Repository.server.user(args[0]);
		Logger.log(user.fullname + " [" + user.email + "]");
		Logger.log();
		Logger.log("Packages:");
		Logger.logList(user.projects);

		return true;
	}

	@usage("package [package ...]")
	@category("information")
	static public function search(args:Array<String>):Bool
	{
		if (args.length == 0) return false;

		var names = new Array<String>();

		// for every argument do a search against haxelib repository
		for (arg in args)
		{
			for (result in Repository.server.search(arg))
			{
				names.push(result.name);
			}
		}

		// print names in columns sorted alphabetically
		Logger.logList(names);

		return true;
	}

}
