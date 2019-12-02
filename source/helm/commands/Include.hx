package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@usage("package...")
@category("information")
class Include implements Command
{
    public function start(parser:ArgParser)
    {
        parser.addArgument({flags: "includes"});
    }

	public function run(args:Namespace, path:Path):Bool
	{
		if (!args.exists("includes")) return false;

		for (name in args.get("includes"))
		{
			Helm.logger.log(Helm.repository.include(name.toLowerCase()).join("\n"));
		}

		return true;
	}
}
