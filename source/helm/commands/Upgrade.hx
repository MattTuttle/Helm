package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@category("development")
@alias("up", "update")
class Upgrade implements Command {
	public function start(parser:ArgParser) {
		parser.addArgument({flags: "includes"});
	}

	public function run(args:Namespace, path:Path):Bool {
		var installer = new Installer();
		var outdated = Helm.repository.outdated(path);
		// TODO: take git repositories into account
		for (item in outdated) {
			installer.install(item.name + ":" + item.latest, path);
		}
		return true;
	}
}
