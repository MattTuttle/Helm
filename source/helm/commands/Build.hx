package helm.commands;

import sys.FileSystem;
import sys.io.File;
import argparse.Namespace;
import argparse.ArgParser;

using StringTools;

@category("development")
@usage("hxml")
class Build implements Command
{
    public function start(parser:ArgParser)
    {
        parser.addArgument({flags: "hxml"});
    }

	public function run(args:Namespace, path:Path):Bool
	{
		var path = Sys.getCwd();

		if (args.exists("hxml"))
		{
            path += args.get("hxml").shift();
		}
		else
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
}
