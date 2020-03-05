package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@category("development")
class Outdated implements Command {
	public function start(parser:ArgParser):Void {}

	public function run(args:Namespace):Bool {
		var outdated = Helm.repository.outdated();
		for (item in outdated) {
			Helm.logger.log(item.name + Config.VERSION_SEP + item.current + " < " + item.latest);
		}
		return true;
	}
}
