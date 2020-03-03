package helm.commands;

import helm.ds.PackageInfo;
import argparse.ArgParser;
import argparse.Namespace;

@category("information")
@alias("l", "ls")
class List implements Command {
	public function start(parser:ArgParser):Void {
		parser.addArgument({flags: ["--flat", "-f"]});
	}

	public function run(args:Namespace, path:Path):Bool {
		var flat = args.exists("flat");

		Helm.logger.log(path);
		var list = Helm.repository.installed(path);
		if (list.length == 0) {
			Helm.logger.log("└── (empty)");
		} else {
			if (flat) {
				printPackagesFlat(list);
			} else {
				printPackages(list);
			}
		}
		return true;
	}

	function printPackagesFlat(list:Array<PackageInfo>) {
		for (p in list) {
			Helm.logger.log(p.fullName);
		}
	}

	function printPackages(list:Array<PackageInfo>) {
		var numItems = list.length, i = 0;
		for (item in list) {
			i += 1;
			var start = "";
			var separator = (i == numItems ? "└" : "├") + "── ";
			Helm.logger.log(start + separator + item.name + "{blue}:" + item.version + "{end}");
		}
	}
}
