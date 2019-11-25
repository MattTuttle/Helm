package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@usage("[--env] package [args...]")
@category("development")
class Run implements Command
{
    public function start(parser:ArgParser):Void
    {
        parser.addArgument({flags: "--env"});
        parser.addArgument({flags: "package", numArgs: 1});
        parser.addArgument({flags: "args"});
    }

	public function run(args:Namespace, path:Path):Bool
	{
		var useEnvironment = args.exists("env"),
			arguments = new Array<String>();

		for (name in args.get("package"))
        {
			path = Helm.repository.findPackage(name);
			for (arg in args.get("args"))
			{
				arguments.push(arg);
			}
		}

		Sys.exit(Helm.repository.run(arguments, path, useEnvironment));

		return true;
	}
}
