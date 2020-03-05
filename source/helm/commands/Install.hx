package helm.commands;

import helm.ds.Lockfile;
import argparse.Namespace;
import argparse.ArgParser;

@usage("[package[:version]...]")
@alias("add", "i", "isntall")
@category("development")
class Install implements Command {
	public function start(parser:ArgParser) {
		parser.addArgument({flags: 'package', numArgs: '?'});
	}

	public function run(args:Namespace):Bool {
		var packages = args.get('package');
		var installer = new Installer();
		// if no packages are given as arguments, search in local directory for dependencies
		if (packages.length == 0) {
			packages = Helm.repository.findDependencies();
		}
		for (requirement in packages) {
			installer.install(requirement);
		}

		return true;
	}
}
