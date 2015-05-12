package helm;

import sys.io.File;
import sys.FileSystem;
import helm.ds.SemVer;
import helm.ds.Types;
import helm.ds.PackageInfo;
import helm.util.*;

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
			var path = Repository.getPackageRoot(Sys.getCwd());
			return path == null ? Sys.getCwd() : path;
		}
	}

	@usage("[package[:version]...]")
	@alias("i", "isntall")
	@category("development")
	static public function install(parser:ArgParser):Bool
	{
		// if no packages are given as arguments, search in local directory for dependencies
		if (parser.complete)
		{
			// TODO: fix install git dependency from haxelib.json
			var path = getPathTarget();
			var libs = Repository.findDependencies(path);

			// install libraries found
			for (lib in libs.keys())
			{
				var name = lib;
				var version:String = libs.get(lib);
				// if version is null it's probably a git repository
				if (version != null && SemVer.ofString(version) == null)
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
				var name:String = parser.current,
					version:SemVer = null;

				// try to split from name@version
				if (name.indexOf("://") == -1)
				{
					var parts = name.split(":");
					if (parts.length == 2)
					{
						version = SemVer.ofString(parts[1]);
						// only use the first part if successfully parsing a version from the second part
						if (version != null) name = parts[0];
					}
				}
				Repository.install(name, version, getPathTarget());
			});
			parser.parse();
		}

		return true;
	}

	@category("development")
	static public function outdated(parser:ArgParser):Bool
	{
		parser.parse();
		var outdated = Repository.outdated(getPathTarget());
		for (item in outdated)
		{
			Logger.log(item.name + ":" + item.current + " < " + item.latest);
		}
		return true;
	}

	@category("development")
	@alias("up", "update")
	static public function upgrade(parser:ArgParser):Bool
	{
		parser.parse();
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
		var flat = false;
		parser.addRule(function(_) { flat = true; }, ["--flat", "-f"]);
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
			if (flat)
			{
				function printPackagesFlat(list:Array<PackageInfo>)
				{
					for (p in list)
					{
						Logger.log(p.fullName);
						printPackagesFlat(Repository.list(p.path));
					}
				}
				printPackagesFlat(list);
			}
			else
			{
				function printPackages(list:Array<PackageInfo>, ?level:Array<Bool>)
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
						var packages = Repository.list(item.path);
						var hasChildren = packages.length > 0;
						var separator = (i == numItems ? "└" : "├") + (hasChildren ? "─┬ " : "── ");
						Logger.log(start + separator + item.name + "{blue}:" + item.version + "{end}");

						if (hasChildren)
						{
							level.push(true);
							printPackages(packages, level);
							level.pop();
						}
					}
				}
				printPackages(list);
			}
		}
		return true;
	}

	@category("development")
	static public function init(parser:ArgParser):Bool
	{
		var path = getPathTarget();
		var info = PackageInfo.load(path);
		if (info != null)
		{
			Logger.error(L10n.get("package_already_exists", [info.fullName]));
		}

		org.haxe.lib.Data.init(path);
		return true;
	}

	@usage("package")
	@category("information")
	static public function which(parser:ArgParser):Bool
	{
		for (arg in parser)
		{
			var repo = Repository.findPackage(arg);
			var info = PackageInfo.load(repo);
			Logger.log(repo + " [" + info.version + "]");
		}
		return true;
	}

	@usage("[--env] package [args...]")
	@category("development")
	static public function run(parser:ArgParser):Bool
	{
		var useEnvironment = false,
			path = getPathTarget(),
			args = new Array<String>();
		parser.addRule(function(_) { useEnvironment = true; }, ["--env"]);
		parser.addRule(function(p:ArgParser) {
			path = Repository.findPackage(p.current);
			for (arg in parser)
			{
				args.push(arg);
			}
		});
		parser.parse();

		Sys.exit(Repository.run(args, path, useEnvironment));

		return true;
	}

	@category("development")
	@alias("rm", "remove")
	static public function uninstall(parser:ArgParser):Bool
	{
		parser.addRule(function(p:ArgParser) {
			var path = getPathTarget();
			var infos = Repository.findPackageIn(p.current, path);
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
				new Directory(path).delete();
				Logger.log(L10n.get("directory_deleted", [p.current]));
			}
		});
		parser.parse();
		return true;
	}

	@category("misc")
	static public function clean(parser:ArgParser):Bool
	{
		var result = Logger.prompt(L10n.get("delete_cache_confirm"));
		if (~/^y(es)?$/.match(result.toLowerCase()))
		{
			new Directory(Config.cachePath).delete();
			Logger.log(L10n.get("cleared_cache"));
		}
		return true;
	}

	@usage("package...")
	@category("information")
	static public function include(parser:ArgParser):Bool
	{
		if (parser.complete) return false;

		for (name in parser)
		{
			Logger.log(Repository.include(name.toLowerCase()).join("\n"));
		}

		return true;
	}

	@usage("[package[:version]...]")
	@category("information")
	static public function info(parser:ArgParser):Bool
	{
		if (parser.complete)
		{
			var path = Repository.getPackageRoot(Sys.getCwd());
			var info = PackageInfo.load(path);
			if (info == null)
			{
				Logger.error(L10n.get("not_a_package"));
			}

			Logger.log(info.fullName);
		}
		else
		{
			for (arg in parser)
			{
				var parts = arg.split(":");
				var info = Repository.server.getProjectInfo(parts[0]);
				if (info == null)
				{
					Logger.error(L10n.get("not_a_package"));
				}

				Logger.log(info.name + " [" + info.website + "]");
				Logger.log(info.description);
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
						if (version.value == requestedVersion)
						{
							Logger.log(L10n.get("info_version", [version.value]));
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
					for (version in info.versions) { versions.push(version.value); }
					Logger.log(L10n.get("info_versions", [info.currentVersion]));
					Logger.logList(versions, false);
				}
				Logger.log("-----------");
			}
		}

		return true;
	}

	@category("development")
	@usage("hxml")
	static public function build(parser:ArgParser):Bool
	{
		var path = Sys.getCwd();
		if (parser.complete)
		{
			// search for hxml files in the current directory
			for (file in sys.FileSystem.readDirectory(path))
			{
				if (StringTools.endsWith(file, ".hxml"))
				{
					path += file;
					break;
				}
			}
		}
		else
		{
			path += parser.next();
		}
		if (!FileSystem.exists(path)) return false;

		var libs = new Map<String, String>(),
			devPaths = new Map<String, String>(),
			data = File.getContent(path);

		// run command where the hxml file is
		var cwd = path.substring(0, path.lastIndexOf("/"));
		Sys.setCwd(cwd);
		// find libraries in the hxml file and try to find their install path
		for (line in data.split("\n"))
		{
			line = line.trim();
			if (line == "" || line.startsWith("#")) continue;

			if (line.startsWith("-lib"))
			{
				var lib = line.substr(4).trim().toLowerCase();
				var path = Repository.findPackage(lib);
				if (path != null) libs.set(lib, path);
			}
		}
		// find current versions of haxelib libraries
		var process = new sys.io.Process("haxelib", ["list"]);
		var lib_regex = ~/^([^:]+): (?:[^ ]+ )*\[dev:([^ ]+)\](?:[^ ]+ )*$/;
		var lines = process.stdout.readAll().toString().split("\n");
		for (line in lines)
		{
			if (lib_regex.match(line))
			{
				var lib = lib_regex.matched(1).toLowerCase();
				if (libs.exists(lib))
				{
					devPaths.set(lib, lib_regex.matched(2));
				}
			}
		}
		// setup haxelib with dev paths
		for (lib in libs.keys())
		{
			var path = libs.get(lib);
			var process = new sys.io.Process("haxelib", ["dev", lib, path]);
			process.close();
		}
		Sys.command("haxe", [path]);
		// put everything back to where it was
		for (lib in libs.keys())
		{
			var args = ["dev", lib];
			if (devPaths.exists(lib)) args.push(devPaths.get(lib));
			var process = new sys.io.Process("haxelib", args);
			process.close();
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

	@usage("register [username] [email]", "user username", "submit")
	@category("haxelib")
	static public function haxelib(parser:ArgParser):Bool
	{
		if (parser.complete) return false;
		switch (parser.next())
		{
			case "register":
				var auth = new Auth();
				auth.register();
			case "user":
				if (parser.complete) return false;

				for (arg in parser)
				{
					var user = Repository.server.getUserInfo(arg);
					if (user == null)
					{
						Logger.log(arg + " is not registered.");
					}
					else
					{
						Logger.log(user.fullName + " [" + user.email + "]");
						Logger.log();
						Logger.log(L10n.get("packages"));
						Logger.logList(user.projects);
					}
				}
			case "publish", "upload", "submit":
				var path = getPathTarget();
				var info = PackageInfo.load(path);
				if (info == null)
				{
					Logger.error(L10n.get("not_a_package"));
				}

				var auth = new Auth();
				auth.login();
				var bundleName = Bundle.make(path);

				Repository.server.submit(info.name, File.read(bundleName).readAll(), auth);
			default:
				return false;
		}

		return true;
	}

	@usage("package...")
	@category("information")
	@alias("find")
	static public function search(parser:ArgParser):Bool
	{
		if (parser.complete) return false;

		var names = new Array<String>();

		// for every argument do a search against haxelib repository
		for (arg in parser)
		{
			for (result in Repository.server.findProject(arg))
			{
				names.push(result.name);
			}
		}

		// print names in columns sorted alphabetically
		Logger.logList(names);

		return true;
	}

}
