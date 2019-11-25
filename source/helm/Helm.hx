package helm;

import argparse.ArgParser;
import argparse.Namespace;
import helm.commands.Command;
import haxe.ds.StringMap;
import haxe.CallStack;
import helm.util.*;

class Helm
{

	static public var VERSION = helm.ds.SemVer.ofString("0.1.0");

	public function new()
	{
		Commands.init();
	}

	public function usage():Void
	{
		Logger.log("{yellow} __ __      _____          __            __ __ ");
		Logger.log("|  |  |    |   __|        |  |          |     |");
		Logger.log("|     |    |   __|        |  |__        | | | |");
		Logger.log("|__|__|{blue}axe {yellow}|_____|{blue}xtended {yellow}|_____|{blue}ibrary {yellow}|_|_|_|{blue}anager   v" + VERSION + "{end}");
		Logger.log();
		Logger.log("{yellow}-g, --global{end}  Use the global library path");
		// Logger.log("{yellow}-u, --user{end}    Use the user library path");
		Logger.log("{yellow}-l, --local{end}   Use the local library path");
		Logger.log("{yellow}-v, --verbose{end} More output for each command");
		Logger.log("{yellow}--no-color{end}    Removes ANSI color output");
		Logger.log("{yellow}--version{end}     Print the current version");
		Logger.log();

		Commands.print();
		Sys.exit(1);
	}

	private function getPathTarget():Path
	{
		if (Config.useGlobal)
		{
			return Config.globalPath;
		}
		else
		{
			var path = Repository.getPackageRoot(Sys.getCwd());
			return path == null ? Sys.getCwd() : path;
		}
	}

	function runCommands(parser:ArgParser, args:Array<String>):Bool
	{
		var result = parser.parse(args);

		if (!result.exists("command"))
		{
			return false;
		}

		for (commandName in result.get("command"))
		{
			var command = Commands.getCommand(commandName);

			if (command != null)
			{
				command.start(parser);
				var result = parser.parse(args);
				var success = command.call(result, getPathTarget());
				if (!success) return false;
			}
		}

		return true;
	}

	public function process(args:Array<String>):Bool
	{
		var parser = new ArgParser();
		parser.addArgument({flags: ["--global", "-g"] });
		parser.addArgument({flags: "--version" });
		parser.addArgument({flags: "--no-color"});
		parser.addArgument({flags: ["-v", "--verbose"]});
		parser.addArgument({flags: "command"});
		var result = parser.parse(args);

		if (result.exists("version")) {
			Logger.log(VERSION);
			Sys.exit(0);
		}

		Logger.COLORIZE = !result.exists("no-color");
		Logger.LEVEL = result.exists("verbose") ? Verbose : Warning;

		return runCommands(parser, args);
	}

	static public function main()
	{
		L10n.init("en-US");

		var lib = new Helm();
		if (!lib.process(Sys.args()))
		{
			lib.usage();
		}
	}

}
