import haxe.ds.StringMap;
import haxe.rtti.Meta;
import haxe.CallStack;

using StringTools;

class Command
{

	public var name(default, null):String;
	public var helpText(default, null):String;
	public var category(default, null):String;
	public var func(default, null):ArgParser->Bool;

	public function new(name:String, meta:Dynamic)
	{
		this.name = name;
		this.helpText = meta.usage != null ? meta.usage.shift() : "";
		this.category = meta.category != null ? meta.category.shift() : "";
		this.func = Reflect.field(Commands, name);
	}

}

class Helm
{

	static public var VERSION = ds.SemVer.ofString("0.1.0");

	public function new()
	{
		_commands = new StringMap<Command>();
		_aliases = new StringMap<Command>();

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
				Logger.log("    helm {yellow}" + command.name + "{end} " + command.helpText);
			}
			Logger.log();
		}
		Sys.exit(1);
	}

	public function process(args:Array<String>):Void
	{
		if (args.length == 0)
		{
			usage();
		}

		var parser = new ArgParser();
		parser.addRule("-g|--global", function(_) { Config.useGlobal = true; });
		parser.addRule("-v|--version", function(_) { Logger.log(VERSION); Sys.exit(0); });
		parser.addRule("--no-color", function(_) { Logger.COLORIZE = false; });
		// parser.addRule("-v|--verbose", function(_) { Logger.LEVEL = Verbose; });
		parser.addRule(null, function(p:ArgParser) {
			try
			{
				var command = p.current;
				var result = false;

				if (_commands.exists(command))
				{
					result = _commands.get(command).func(p);
				}
				else if (_aliases.exists(command))
				{
					result = _aliases.get(command).func(p);
				}

				if (!result)
				{
					usage();
				}
			}
			catch (e:Dynamic)
			{
				Logger.log(Std.string(e));
				Logger.log(CallStack.toString(CallStack.exceptionStack()));
			}
		});
		parser.parse(args);
	}

	static public function main()
	{
		L10n.init();
		Config.load();

		var lib = new Helm();
		lib.process(Sys.args());
	}

	private var _commands:StringMap<Command>;
	private var _aliases:StringMap<Command>;

}
