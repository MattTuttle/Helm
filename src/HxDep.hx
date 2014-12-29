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

class HxDep
{

	public function new()
	{
		_commands = new StringMap<Command>();
		var methods = Meta.getStatics(Commands);
		for (name in Reflect.fields(methods))
		{
			addCommand(name, Reflect.field(methods, name));
		}
	}

	private function addCommand(name:String, meta:Dynamic):Void
	{
		var usage = meta.usage.shift();
		_commands.set(name, new Command(name, usage));
	}

	public function usage():Void
	{
		Sys.println("Usage:");
		for (command in _commands)
		{
			Sys.println("  hxl " + command.name + " " + command.helpText);
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
				Sys.println(e);
				return;
			}
		}

		if (!result)
		{
			usage();
		}
	}

	private var _commands:StringMap<Command>;

}
