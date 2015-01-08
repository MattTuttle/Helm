import haxe.ds.StringMap;
import haxe.rtti.Meta;
import haxe.CallStack;

using StringTools;

class Command
{

	public var name(default, null):String;
	public var helpText(default, null):String;
	public var category(default, null):String;
	public var func(default, null):Array<String>->Bool;

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

	inline static public var VERSION:ds.SemVer = "0.1.0";

	public function new()
	{
		_commands = new StringMap<Command>();
		_aliases = new StringMap<Command>();

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
		Logger.log("\x1b[34;1m __ __      _____          __            __ __ ");
		Logger.log("|  |  |    |   __|        |  |          |     |");
		Logger.log("|     |    |   __|        |  |__        | | | |");
		Logger.log("|__|__|axe |_____|xtended |_____|ibrary |_|_|_|anager   v" + VERSION + "\x1b[0m");
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
			Logger.log("-- " + category + " --");
			var list = categories.get(category);
			list.sort(function(a:Command, b:Command):Int {
				return (a.name > b.name ? 1 : (a.name < b.name ? -1 : 0));
			});
			for (command in list)
			{
				Logger.log("    helm " + command.name + " " + command.helpText);
			}
			Logger.log();
		}
		Sys.exit(1);
	}

	public function process(args:Array<String>):Void
	{
		try
		{
			if (args.length == 0)
			{
				usage();
			}

			var command = args.shift();
			var result = false;

			if (_commands.exists(command))
			{
				result = _commands.get(command).func(args);
			}
			else if (_aliases.exists(command))
			{
				result = _aliases.get(command).func(args);
			}

			if (!result)
			{
				usage();
			}
		}
		catch (e:Dynamic)
		{
			Logger.log(Std.string(e));
			#if debug
			Logger.log(CallStack.toString(CallStack.exceptionStack()));
			#end
		}
	}

	static public function main()
	{
		var args = Sys.args();
		Config.load();

		var list = new Array<String>();
		var flags = new Array<String>();
		for (arg in args)
		{
			if (arg.startsWith("-"))
			{
				if (arg.startsWith("--"))
				{
					flags.push(arg);
				}
				else
				{
					// convert single dash flags to double dash
					arg = arg.substr(1);
					for (i in 0...arg.length)
					{
						switch (arg.charAt(i))
						{
							case "g":
								flags.push("--global");
							case "v":
								flags.push(args.length == 1 ? "--version" : "--verbose");
							default:
								Logger.log("Unknown flag -" + arg.charAt(i));
						}
					}
				}
			}
			else
			{
				list.push(arg);
			}
		}

		for (flag in flags)
		{
			switch (flag)
			{
				case "--global":
					Config.useGlobal = true;
				case "--version":
					Logger.log(VERSION);
					Sys.exit(0);
				case "--verbose":
					Logger.LEVEL = Verbose;
			}
		}

		var lib = new Helm();
		lib.process(list);
	}

	private var _commands:StringMap<Command>;
	private var _aliases:StringMap<Command>;

}
