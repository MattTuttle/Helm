package helm.commands;

import helm.util.Logger;
import helm.util.L10n;
import helm.ds.PackageInfo;
import argparse.ArgParser;
import argparse.Namespace;

@category("development")
class Init implements Command
{
    public function start(parser:ArgParser)
    {
    }

	public function run(args:Namespace, path:Path):Bool
	{
		var info = PackageInfo.load(path);
		if (info != null)
		{
			Helm.logger.error(L10n.get("package_already_exists", [info.fullName]));
		}

		org.haxe.lib.Data.init(path, Helm.logger);
		return true;
	}
}
