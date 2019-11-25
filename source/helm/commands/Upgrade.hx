package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@category("development")
@alias("up", "update")
class Upgrade implements Command
{
    public function start(parser:ArgParser)
    {
        parser.addArgument({flags: "includes"});
    }

	public function run(args:Namespace, path:Path):Bool
	{
		var outdated = Helm.repository.outdated(path);
		for (item in outdated)
		{
			Helm.repository.install(item.name, item.latest, path);
		}
		return true;
	}
}
