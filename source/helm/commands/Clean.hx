package helm.commands;

import helm.util.L10n;
import helm.util.Logger;
import argparse.ArgParser;
import argparse.Namespace;

@category("misc")
class Clean implements Command
{
    public function start(parser:ArgParser):Void
    {

    }

	public function run(args:Namespace, path:Path):Bool
	{
		var result = Logger.prompt(L10n.get("delete_cache_confirm"));
		if (~/^y(es)?$/.match(result.toLowerCase()))
		{
			new Directory(Config.cachePath).delete();
			Logger.log(L10n.get("cleared_cache"));
		}
		return true;
	}
}
