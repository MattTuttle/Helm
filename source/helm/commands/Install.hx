package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;
import helm.ds.SemVer;

@usage("[package[:version]...]")
@alias("add", "i", "isntall")
@category("development")
class Install implements Command {
	public function start(parser:ArgParser) {
		parser.addArgument({flags: 'package', numArgs: '?'});
	}

	function installAll(path:Path) {
		// TODO: fix install git dependency from haxelib.json
		var libs = Helm.repository.findDependencies(path);
		var installer = new Installer();

		// install libraries found
		for (lib in libs.keys()) {
			var name = lib;
			var version:String = libs.get(lib);
			// if version is null it's probably a git repository
			if (version != null && SemVer.ofString(version) == null) {
				name = libs.get(lib);
			}
			installer.install(name + ":" + path, path);
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
