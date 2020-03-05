package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@category("development")
@alias("package")
class Bundle implements Command {
	public function start(parser:ArgParser):Void {}

	public function run(args:Namespace):Bool {
		LibBundle.make(Helm.project.path);
		return true;
	}
}
