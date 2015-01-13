package helm;

import sys.io.File;
import sys.FileSystem;
import helm.ds.SemVer;
import helm.ds.Types;

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
			var path = Repository.getPackageRoot(Sys.getCwd(), haxelib.Data.JSON);
			return path == null ? Sys.getCwd() : path;
		}
	}

	@usage("[package [version]]")
	@alias("i", "isntall")
	@category("development")
	static public function install(parser:ArgParser):Bool
	{
		// if no packages are given as arguments, search in local directory for dependencies
		if (parser.complete)
		{
			var path = getPathTarget();
			var libs = Repository.findDependencies(path);

			// install libraries found
			for (lib in libs.keys())
			{
				var name = lib;
				var version:SemVer = libs.get(lib);
				// if version is null it's probably a git repository
				if (version == null)
				{
					name = libs.get(lib);
				}
				Repository.install(name, version, path);
			}
		}
		else
		{
			// default rule
			parser.addRule(function(_) {
				var parts = parser.current.split("@");
				var version = parts.length > 1 ? SemVer.ofString(parts[1]) : null;
				Repository.install(parts[0], version, getPathTarget());
			});
			parser.parse();
		}

		return true;
	}

	@category("development")
	static public function outdated(parser:ArgParser):Bool
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
	static public function upgrade(parser:ArgParser):Bool
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
	static public function list(parser:ArgParser):Bool
	{
		parser.parse(); // continue parsing
		var path = getPathTarget();

		Logger.log(path);
		var list = Repository.list(path);
		if (list.length == 0)
		{
			Logger.log("└── (empty)");
		}
		else
		{
			if (parser.complete)
			{
				Repository.printPackages(list);
			}
			else
			{
				parser.addRule(function(_) {
					function printPackagesFlat(list:Array<PackageInfo>)
					{
						for (p in list)
						{
							Logger.log(p.fullName);
							printPackagesFlat(p.packages);
						}
					}
					printPackagesFlat(list);
				}, ["--flat", "-f"]);
				parser.parse();
			}
		}
		return true;
	}

	@category("development")
	static public function init(parser:ArgParser):Bool
	{
		// TODO: make this interactive and less crappy...
		var path = getPathTarget();
		var info = Repository.loadPackageInfo(path);
		if (info != null) throw "Package " + info.fullName + " already exists!";

		var data = new haxelib.Data();
		data.name = Logger.prompt(L10n.get("init_project_name"));
		data.description = Logger.prompt(L10n.get("init_project_description"));
		data.version = Logger.prompt(L10n.get("init_project_version"), "0.1.0");
		data.url = Logger.prompt(L10n.get("init_project_url"));
		data.license = Logger.prompt(L10n.get("init_project_license"), "MIT");

		var out = sys.io.File.write(haxelib.Data.JSON);
		out.writeString(data.toString());
		out.close();

		return true;
	}

	@usage("package")
	@category("information")
	static public function which(parser:ArgParser):Bool
	{
		for (arg in parser)
		{
			var repo = Repository.findPackage(arg);
			var info = Repository.loadPackageInfo(repo);
			Logger.log(repo + " [" + info.version + "]");
		}
		return true;
	}

	@usage("package [args ...]")
	@category("development")
	static public function run(parser:ArgParser):Bool
	{
		if (parser.complete) return false;

		var name = parser.iterator().next();

		var args = new Array<String>();
		for (arg in parser)
		{
			args.push(arg);
		}
		var repo = Repository.findPackage(name);
		var run = "run.n";

		// TODO: add ability to run program with haxe command instead of neko

		if (!FileSystem.exists(repo + run))
		{
			throw L10n.get("run_not_enabled", [name]);
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
	static public function uninstall(parser:ArgParser):Bool
	{
		var path = getPathTarget();

		for (arg in parser)
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
				Logger.log(L10n.get("directory_deleted", [arg]));
			}
		}
		return true;
	}

	@category("misc")
	static public function clean(parser:ArgParser):Bool
	{
		var result = Logger.prompt(L10n.get("delete_cache_confirm"));
		if (~/^y(es)?$/.match(result.toLowerCase()))
		{
			Directory.delete(Config.cachePath);
			Logger.log(L10n.get("cleared_cache"));
		}
		return true;
	}

	@usage("package [package ...]")
	@category("information")
	@alias("path")
	static public function include(parser:ArgParser):Bool
	{
		if (parser.complete) return false;

		for (name in parser)
		{
			Repository.printInclude(name);
		}

		return true;
	}

	@usage("package [version]")
	@category("information")
	static public function info(parser:ArgParser):Bool
	{
		if (parser.complete)
		{
			var path = Repository.getPackageRoot(Sys.getCwd(), haxelib.Data.JSON);
			var info = Repository.loadPackageInfo(path);
			if (info == null)
			{
				Logger.log(L10n.get("not_a_package"));
			}
			else
			{
				Logger.log(info.fullName);
			}
		}
		else
		{
			for (arg in parser)
			{
				var parts = arg.split("@");
				var info = Repository.server.infos(parts[0]);

				Logger.log(info.name + " [" + info.website + "]");
				Logger.log(info.desc);
				Logger.log();
				Logger.log(L10n.get("info_owner", [info.owner]));
				Logger.log(L10n.get("info_license", [info.license]));
				Logger.log(L10n.get("info_tags", [info.tags.join(", ")]));
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
							Logger.log(L10n.get("info_version", [version.name]));
							Logger.log(L10n.get("info_date", [version.date]));
							Logger.log(L10n.get("info_comments", [version.comments]));
							found = true;
							break;
						}
					}
					if (!found)
					{
						Logger.log(L10n.get("version_not_found", [requestedVersion]));
					}
				}
				else
				{
					var versions = new Array<String>();
					for (version in info.versions) { versions.push(version.name); }
					Logger.log(L10n.get("info_versions", [info.curversion]));
					Logger.logList(versions, false);
				}
				Logger.log("-----------");
			}
		}

		return true;
	}

	@category("development")
	@alias("package")
	static public function bundle(parser:ArgParser):Bool
	{
		var path = getPathTarget();
		Bundle.make(path);
		return true;
	}

	@category("development")
	@alias("upload", "submit")
	static public function publish(parser:ArgParser):Bool
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
	static public function register(parser:ArgParser):Bool
	{
		var auth = new Auth();
		auth.register();
		return true;
	}

	@usage("username")
	@category("profile")
	static public function user(parser:ArgParser):Bool
	{
		if (parser.complete) return false;

		for (arg in parser)
		{
			var user = Repository.server.user(arg);
			Logger.log(user.fullname + " [" + user.email + "]");
			Logger.log();
			Logger.log(L10n.get("packages"));
			Logger.logList(user.projects);
		}

		return true;
	}

	@usage("package [package ...]")
	@category("information")
	static public function search(parser:ArgParser):Bool
	{
		if (parser.complete) return false;

		var names = new Array<String>();

		// for every argument do a search against haxelib repository
		for (arg in parser)
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
