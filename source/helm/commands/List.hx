package helm.commands;

import helm.ds.PackageInfo;
import helm.util.Logger;
import argparse.ArgParser;
import argparse.Namespace;

@category("information")
@alias("l", "ls")
class List implements Command
{
    public function start(parser:ArgParser):Void
    {
        parser.addArgument({flags: ["--flat", "-f"]});
    }

	public function run(args:Namespace, path:Path):Bool
	{
		var flat = args.exists("flat");

		Logger.log(path);
		var list = Repository.list(path);
		if (list.length == 0)
		{
			Logger.log("└── (empty)");
		}
		else
		{
			if (flat)
			{
				function printPackagesFlat(list:Array<PackageInfo>)
				{
					for (p in list)
					{
						Logger.log(p.fullName);
						printPackagesFlat(Repository.list(p.path));
					}
				}
				printPackagesFlat(list);
			}
			else
			{
				function printPackages(list:Array<PackageInfo>, ?level:Array<Bool>)
				{
					if (level == null) level = [true];

					var numItems = list.length, i = 0;
					for (item in list)
					{
						i += 1;
						var start = "";
						level[level.length - 1] = (i == numItems);
						for (j in 0...level.length - 1)
						{
							start += (level[j] ? "  " : "│ ");
						}
						var packages = Repository.list(item.path);
						var hasChildren = packages.length > 0;
						var separator = (i == numItems ? "└" : "├") + (hasChildren ? "─┬ " : "── ");
						Logger.log(start + separator + item.name + "{blue}:" + item.version + "{end}");

						if (hasChildren)
						{
							level.push(true);
							printPackages(packages, level);
							level.pop();
						}
					}
				}
				printPackages(list);
			}
		}
		return true;
	}
}
