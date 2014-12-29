import haxe.ds.StringMap;

class Command
{

	public var name(default, null):String;
	public var helpText(default, null):String;
	public var func(default, null):Array<String>->Bool;

	public function new(name:String, helpText:String, func:Array<String>->Bool)
	{
		this.name = name;
		this.helpText = helpText;
		this.func = func;
	}

}

class HxDep
{

	public function new()
	{
		commands = new StringMap<Command>();
		addCommand("install", "package [version]", Commands.install);
		addCommand("path", "package [package ...]", Commands.path);
		addCommand("search", "package [package ...]", Commands.search);
		addCommand("info", "package [version]", Commands.info);
		addCommand("user", "username", Commands.user);
		addCommand("register", "[username] [email]", Commands.register);
	}

	private function addCommand(name:String, helpText:String, func:Array<String>->Bool):Void
	{
		commands.set(name, new Command(name, helpText, func));
	}

	public function usage():Void
	{
		Sys.println("Usage:");
		for (command in commands)
		{
			Sys.println("  hxl " + command.name + " " + command.helpText);
		}
	}

	public function process(command:String, args:Array<String>):Void
	{
		var result = false;
		if (commands.exists(command))
		{
			try
			{
				result = commands.get(command).func(args);
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

	private var commands:StringMap<Command>;

}
