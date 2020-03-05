package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

using StringTools;

@category("development")
@usage("hxml")
class Build implements Command {
	public function start(parser:ArgParser) {
		parser.addArgument({flags: "hxml", numArgs: '?'});
	}

	public function run(args:Namespace):Bool {
		var result = true;

		var path = Helm.project.path;
		if (args.exists("hxml")) {
			for (hxml in args.get("hxml")) {
				result = buildHxmlFile(path.join(hxml));
			}
		} else {
			// build all hxml files in the current directory
			for (file in FileSystem.readDirectory(path)) {
				if (StringTools.endsWith(file, ".hxml") && !buildHxmlFile(path.join(file))) {
					result = false;
				}
			}
		}
		return result;
	}

	function buildHxmlFile(path:Path):Bool {
		if (FileSystem.isFile(path)) {
			return Sys.command("haxe", [path]) == 0;
		}
		return false;
	}
}
