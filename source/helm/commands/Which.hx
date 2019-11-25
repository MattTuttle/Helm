package helm.commands;

import helm.util.Logger;
import helm.ds.PackageInfo;
import argparse.ArgParser;
import argparse.Namespace;

@usage("package")
@category("information")
class Which implements Command
{
    public function start(parser:ArgParser)
    {
        parser.addArgument({flags: "package"});
    }

	public function run(args:Namespace, path:Path):Bool
	{
        if (!args.exists("package")) return false;

		for (arg in args.get("package"))
		{
			var repo = Repository.findPackage(arg);
			var info = PackageInfo.load(repo);
			Helm.logger.log(repo + " [" + info.version + "]");
		}
		return true;
	}
}
