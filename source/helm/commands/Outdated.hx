package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@category("development")
class Outdated implements Command {
	public function start(parser:ArgParser):Void {}

	public function run(args:Namespace, path:Path):Bool {
		var outdated = Helm.repository.outdated(path);
		for (item in outdated) {
			Helm.logger.log(item.name + ":" + item.current + " < " + item.latest);
		}
		return true;
	}
}
