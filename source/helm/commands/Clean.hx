package helm.commands;

import helm.FileSystem;
import helm.util.L10n;
import argparse.ArgParser;
import argparse.Namespace;

@category("misc")
class Clean implements Command {
	public function start(parser:ArgParser):Void {}

	public function run(args:Namespace, path:Path):Bool {
		var result = Helm.logger.prompt(L10n.get("delete_cache_confirm"));
		if (~/^y(es)?$/.match(result.toLowerCase())) {
			FileSystem.delete(Config.cachePath);
			Helm.logger.log(L10n.get("cleared_cache"));
		}
		return true;
	}
}
