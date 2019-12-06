package helm.commands;

import helm.util.L10n;
import argparse.Namespace;
import argparse.ArgParser;

@category("development")
@alias("rm", "remove")
class Uninstall implements Command {
	public function start(parser:ArgParser):Void {
		parser.addArgument({flags: "packages"});
	}

	public function run(args:Namespace, path:Path):Bool {
		for (packageName in args.get("packages")) {
			var infos = Helm.repository.findPackagesIn(packageName, path);
			for (info in infos) {
				FileSystem.delete(info.filePath.dirname().dirname());
				Helm.logger.log(L10n.get("directory_deleted", [info.name]));
			}
		}
		return true;
	}
}
