package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;

@category("development")
@alias("package")
class Bundle implements Command
{
    public function start(parser:ArgParser):Void
    {
    }

	public function run(args:Namespace, path:Path):Bool
	{
		LibBundle.make(path);
		return true;
	}
}
