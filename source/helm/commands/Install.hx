package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@usage("[package[:version]...]")
@alias("add", "i", "isntall")
@category("development")
class Install implements Command {
	public function start(parser:ArgParser) {
		parser.addArgument({flags: 'package', numArgs: '?'});
	}

	function installAll(path:Path) {
		var dependencies = Helm.repository.findDependencies(path);
		var installer = new Installer();

		// install dependencies found
		for (requirement in dependencies) {
			installer.install(requirement, path);
		}
	}

	function installPackage(name:String, path:Path) {
		var installer = new Installer();
		installer.install(name, path);
	}

	public function run(args:Namespace, path:Path):Bool {
		var packages = args.get('package');
		// if no packages are given as arguments, search in local directory for dependencies
		if (packages.length == 0) {
			installAll(path);
		} else {
			// default rule
			for (name in packages) {
				installPackage(name, path);
			}
		}

		return true;
	}
}
