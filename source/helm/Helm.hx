package helm;

import haxe.ds.StringMap;
import haxe.rtti.Meta;
import haxe.CallStack;
import helm.util.*;
import argparse.ArgParser;
import argparse.Namespace;

using StringTools;

class Command
{

	public var name(default, null):String;
	public var helpText(default, null):String = "";
	public var category(default, null):String;
	public var call(default, null):Namespace->Bool;

	public function new(name:String, meta:Dynamic)
	{
		this.name = name;
		if (meta.usage != null)
		{
			if (meta.usage.length == 1)
			{
				this.helpText = meta.usage.shift();
			}
			else
			{
				var sep = "\n        ";
				this.helpText += "command\n      {blue}Commands:{end}" + sep + meta.usage.join(sep);
			}
		}
		this.category = meta.category != null ? meta.category.shift() : "";
		this.call = Reflect.field(Commands, name);
	}

}

class Helm
{

	static public var VERSION = helm.ds.SemVer.ofString("0.1.0");

	public function new()
	{
		_commands = new StringMap<Command>();
		_aliases = new StringMap<Command>();
		createCommands();
	}

	function createCommands():Void
	{
		// TODO: use a macro instead of runtime metadata??
		var methods = Meta.getStatics(Commands);
		for (name in Reflect.fields(methods))
		{
			var meta = Reflect.field(methods, name);

			var command = new Command(name, meta);
			_commands.set(name, command);

			// don't group aliases with commands so they don't show on the help screen
			if (meta.alias != null)
			{
				for (alias in cast(meta.alias, Array<Dynamic>))
				{
					_aliases.set(alias, command);
				}
			}
		}
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

		var categories = new StringMap<Array<Command>>();
		for (command in _commands)
		{
			var list = categories.exists(command.category) ? categories.get(command.category) : new Array<Command>();
			list.push(command);
			categories.set(command.category, list);
		}
		for (category in categories.keys())
		{
			Logger.log("{blue}-- " + category + " --{end}");
			var list = categories.get(category);
			list.sort(function(a:Command, b:Command):Int {
				return (a.name > b.name ? 1 : (a.name < b.name ? -1 : 0));
			});
			for (command in list)
			{
				Logger.log('    helm {yellow}${command.name}{end} ${command.helpText}');
			}
			Logger.log();
		}
		Sys.exit(1);
	}

	public function process(args:Array<String>):Bool
	{
		var success = false;

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

		for (command in result.get("command"))
		{
			try
			{
				if (_commands.exists(command))
				{
					success = _commands.get(command).call(result);
				}
				else if (_aliases.exists(command))
				{
					success = _aliases.get(command).call(result);
				}
				else
				{
					// TODO: make suggestion for command?
				}
			}
			catch (e:Dynamic)
			{
				Logger.log(Std.string(e));
				Logger.log(CallStack.toString(CallStack.exceptionStack()));
			}
		}

		return success;
	}

	static public function main()
	{
		L10n.init();

		var lib = new Helm();
		if (!lib.process(Sys.args()))
		{
			lib.usage();
		}
	}

	private var _commands:StringMap<Command>;
	private var _aliases:StringMap<Command>;

}
