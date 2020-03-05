package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@category("development")
@alias("up", "update")
class Upgrade implements Command {
	public function start(parser:ArgParser) {
		parser.addArgument({flags: "includes"});
	}

	public function run(args:Namespace):Bool {
		var installer = new Installer();
		var outdated = Helm.repository.outdated();
		// TODO: take git repositories into account
		installer.install([
			for (item in outdated)
				item.name + Config.VERSION_SEP + item.latest
		]);
		return true;
	}
}
