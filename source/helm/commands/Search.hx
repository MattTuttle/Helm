package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@usage("package...")
@category("information")
@alias("find")
class Search implements Command {
	public function start(parser:ArgParser):Void {
		parser.addArgument({flags: "package"});
	}

	public function run(args:Namespace):Bool {
		if (args.exists("package")) {
			var names = new Array<String>();

			// for every argument do a search against haxelib repository
			for (arg in args.get("package")) {
				for (result in Helm.registry.search(arg)) {
					names.push(result);
				}
			}

			// print names in columns sorted alphabetically
			Helm.logger.logList(names);

			return true;
		}

		return false;
	}
}
