import haxe.ds.StringMap;
import haxe.rtti.Meta;

class Command
{

	public var name(default, null):String;
	public var helpText(default, null):String;
	public var category(default, null):String;
	public var func(default, null):Array<String>->Bool;

	public function new(name:String, helpText:String, category:String)
	{
		this.name = name;
		this.helpText = helpText;
		this.category = category;
		this.func = Reflect.field(Commands, name);
	}

}

class Haxelib
{

	public function new()
	{
		_commands = new StringMap<Command>();
		var methods = Meta.getStatics(Commands);
		for (name in Reflect.fields(methods))
		{
			var meta = Reflect.field(methods, name);
			var usage = meta.usage != null ? meta.usage.shift() : "";
			var category = meta.category != null ? meta.category.shift() : "";
			_commands.set(name, new Command(name, usage, category));
		}
	}

	public function usage():Void
	{
		Logger.log("Usage:");
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
				Logger.log("    haxelib " + command.name + " " + command.helpText);
			}
			Logger.log();
		}
	}

	public function process(args:Array<String>):Void
	{
		var result = false;
		var command = args.shift();
		if (_commands.exists(command))
		{
			try
			{
				result = _commands.get(command).func(args);
			}
			catch (e:Dynamic)
			{
				Logger.log(Std.string(e));
				return;
			}
		}

		if (!result)
		{
			usage();
		}
	}

	static public function main()
	{
		var args = Sys.args();

		var lib = new Haxelib();
		if (args.length < 1)
		{
			lib.usage();
		}
		else
		{
			lib.process(args);
		}
	}

	private var _commands:StringMap<Command>;

}
