package helm;

import helm.registry.Registry;
import helm.util.Logger.LogLevel;
import argparse.ArgParser;
import helm.util.*;

class Helm
{

	static public var VERSION = helm.ds.SemVer.ofString("0.1.0");
	static public var logger = new Logger(Sys.stdout());
	static public var repository = new Repository();
	// TODO: setup a mirror list for multiple repository servers

	static public var registry:Registry = new helm.registry.Haxelib();

	public function new()
	{
		Commands.init();
	}

	public function usage():Void
	{
		Helm.logger.log("{yellow} __ __      _____          __            __ __ ");
		Helm.logger.log("|  |  |    |   __|        |  |          |     |");
		Helm.logger.log("|     |    |   __|        |  |__        | | | |");
		Helm.logger.log("|__|__|{blue}axe {yellow}|_____|{blue}xtended {yellow}|_____|{blue}ibrary {yellow}|_|_|_|{blue}anager   v" + VERSION + "{end}");
		Helm.logger.log();
		Helm.logger.log("{yellow}-g, --global{end}  Use the global library path");
		Helm.logger.log("{yellow}-l, --local{end}   Use the local library path");
		Helm.logger.log("{yellow}-v, --verbose{end} More output for each command");
		Helm.logger.log("{yellow}--no-color{end}    Removes ANSI color output");
		Helm.logger.log("{yellow}--version{end}     Print the current version");
		Helm.logger.log();

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
			var cwd:Path = Sys.getCwd(); // current working directory
			cwd = cwd.normalize(); // cwd has a nasty habit of including a trailing slash
			var path = Helm.repository.getPackageRoot(cwd);
			return path == null ? cwd : path;
		}
	}

	function runCommands(parser:ArgParser, args:Array<String>):Bool
	{
		var result = parser.parse(args, false);

		if (!result.exists("command"))
		{
			return false;
		}

		var path = getPathTarget();
		for (commandName in result.get("command"))
		{
			var command = Commands.getCommand(commandName);

			// if a command can't be found, try it as a run command
			if (command == null)
			{
				command = Commands.getCommand("run");
				args.unshift("run");
			}

			command.start(parser);
			var result = parser.parse(args);
			var success = command.call(result, path);
			if (!success) return false;
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
		var result = parser.parse(args, false);

		var logLevel:LogLevel = result.exists("verbose") ? Verbose : Warning;
		var colorize = !result.exists("no-color");
		Helm.logger = new Logger(Sys.stdout(), logLevel, colorize);

		if (result.exists("version")) {
			Helm.logger.log(VERSION);
			Sys.exit(0);
		}

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
