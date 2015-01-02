import haxe.crypto.Md5;
import sys.io.File;
import sys.FileSystem;
import tools.haxelib.SemVer;
import tools.haxelib.Data;

using StringTools;

class Commands
{

	static private function getPathTarget(args:Array<String>):String
	{
		var path = Sys.getCwd();
		for (arg in args)
		{
			switch (arg)
			{
				case "-g":
					path = Config.globalPath;
					args.remove(arg);
			}
		}
		return path;
	}

	@usage("[package [version]]")
	@alias("isntall")
	@category("development")
	static public function install(args:Array<String>):Bool
	{
		if (args.length > 2) return false;

		var path = getPathTarget(args);

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
	static public function upgrade(args:Array<String>):Bool
	{
		var path = getPathTarget(args);
		var list = Repository.list(path);
		trace(list);
		return true;
	}

	@category("information")
	@alias("l", "ls")
	static public function list(args:Array<String>):Bool
	{
		var path = getPathTarget(args);

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
	@alias("rm")
	static public function remove(args:Array<String>):Bool
	{
		var path = getPathTarget(args);

		for (arg in args)
		{
			var path = Repository.findPackageIn(arg, path);
			if (path != null)
			{
				Directory.delete(path);
				Logger.log("Removed " + arg);
			}
		}
		return true;
	}

	@category("misc")
	static public function clean(args:Array<String>):Bool
	{
		// TODO: prompt warning and only delete older versions unless forced to clear everything
		Directory.delete(Config.cachePath);
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
			// TODO: error handling if invalid version passed or if no version is found
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

	static private function prompt(msg:String, secure:Bool = false):String
	{
		Logger.log(msg, false);
		if (secure)
		{
			var buffer = new StringBuf(),
				result = null;
			while (true)
			{
				switch (Sys.getChar(false))
				{
					case 3: // Ctrl+C
						Logger.log();
						Sys.exit(1); // cancel
					case 10, 13: // new line
						result = buffer.toString();
						break;
					case c:
						buffer.addChar(c);
				}
			}
			Logger.log("<secure>");
			return result;
		}
		return Sys.stdin().readLine();
	}

	@category("development")
	@alias("upload", "submit")
	static public function publish(args:Array<String>):Bool
	{
		var username = login();
		trace(username);
		return true;
	}

	static private function login():String
	{
		var username:String, password:String;
		while (true)
		{
			username = prompt("Username: ").toLowerCase();
			if (!Repository.instance.isNewUser(username)) break;
			Logger.log("Username is not registered.");
		}
		while (true)
		{
			password = Md5.encode(prompt("Password: ", true));
			if (Repository.instance.checkPassword(username, password)) break;
			Logger.log("Invalid password.");
		}
		return username;
	}

	@usage("[username] [email]")
	@category("profile")
	static public function register(args:Array<String>):Bool
	{
		var proxy = Repository.instance;
		var username_regex = ~/^[a-z0-9_-]{3,32}$/;
		var email_regex = ~/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
		while (true)
		{
			var password:String, email:String;
			var username = prompt("Username: ").toLowerCase();
			if (!username_regex.match(username))
			{
				Logger.log("Invalid username. Must be alphanumeric and 3-32 characters long.");
				continue;
			}

			if (!proxy.isNewUser(username))
			{
				Logger.log("Username " + username + " is already taken");
				continue;
			}

			while (true)
			{
				password = prompt("Password: ", true);
				var confirm = prompt("Confirm Password: ", true);
				if (password == confirm) break;
				Logger.log("Passwords didn't match.");
			}
			password = Md5.encode(password);

			while(true)
			{
				email = prompt("Email: ");
				if (email_regex.match(email)) break;
				Logger.log("Invalid email address.");
			}

			var name = prompt("Full Name: ");

			proxy.register(username, password, email, name);
			break;
		}
		return true;
	}

	@usage("username")
	@category("profile")
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
	@category("information")
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
