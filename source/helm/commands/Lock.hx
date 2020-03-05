package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@category("development")
class Lock implements Command {
	public function start(parser:ArgParser) {}

	public function run(args:Namespace):Bool {
		Helm.project.lockfile();
		return true;
	}
}
