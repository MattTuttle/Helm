package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@category("development")
class Lock implements Command {
	public function start(parser:ArgParser) {}

	public function run(args:Namespace, path:Path):Bool {
		var projectRoot = Helm.project.getRoot(path);
		var lockfile = Helm.project.lockfile(projectRoot);
		lockfile.save(projectRoot);
		return true;
	}
}
