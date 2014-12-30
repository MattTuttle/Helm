import haxe.ds.StringMap;
import haxe.rtti.Meta;

class Command
{

	public var name(default, null):String;
	public var helpText(default, null):String;
	public var func(default, null):Array<String>->Bool;

	public function new(name:String, helpText:String)
	{
		this.name = name;
		this.helpText = helpText;
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
			_commands.set(name, new Command(name, usage));
		}
	}

	public function usage():Void
	{
		Logger.log("Usage:");
		for (command in _commands)
		{
			Logger.log("  haxelib " + command.name + " " + command.helpText);
		}
	}

	public function process(command:String, args:Array<String>):Void
	{
		var result = false;
		if (_commands.exists(command))
		{
			try
			{
				result = _commands.get(command).func(args);
			}
			catch (e:Dynamic)
			{
				Logger.log(e);
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
			var command = args.shift();
			lib.process(command, args);
		}
	}

	private var _commands:StringMap<Command>;

}
