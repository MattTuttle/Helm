package helm;

import argparse.Namespace;
import argparse.ArgParser;
import haxe.ds.StringMap;
import helm.commands.Command;
import haxe.rtti.Meta;
import helm.util.Logger;
import haxe.CallStack;

class CommandCall
{

    public final name:String;
	public final helpText:String = "";
	public final category:String;
	public final aliases:Array<String>;

	final _command:Command;

	public function start(parser:ArgParser)
	{
		_command.start(parser);
	}

	public function call(args:Namespace, path:String):Bool
	{
		// wrap in a try/catch; so if the command explodes it can exit gracefully
		try
		{
			return _command.run(args, path);
		}
		catch (e:Dynamic)
		{
			Logger.log(Std.string(e));
			Logger.log(CallStack.toString(CallStack.exceptionStack()));
		}
		return false;
	}

	public function new(command:Class<Command>)
	{
		var meta = Meta.getType(command);
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
        // grab a list of aliases
		this.aliases = meta.alias == null ? [] : cast meta.alias;
        // get class name from path
        this.name = Type.getClassName(command).split('.').pop();
        // add lowercase name as the first alias
        this.aliases.unshift(name.toLowerCase());
        // set the category, if any
		this.category = meta.category == null ? "" : meta.category.shift();
        // create an instance of the class and store it for later calls
		this._command = Type.createEmptyInstance(command);
	}

}

class Commands
{
    public static function init()
    {
        CompileTime.importPackage("helm.commands");
		var commands = CompileTime.getAllClasses('helm.commands');
        for (command in commands)
        {
            addCommand(command);
        }
    }

	static function addCommand(command:Class<Command>)
	{
		var command = new CommandCall(command);
        _commands.push(command);
		for (alias in command.aliases)
		{
			_aliases.set(alias, command);
		}
	}

	public static function getCommand(name:String):Null<CommandCall>
	{
		return _aliases.get(name);
	}

	public static function print():Void
	{
		var categories = new StringMap<Array<CommandCall>>();
		for (command in _commands)
		{
			var category = command.category;
			var list = categories.exists(category) ? categories.get(category) : [];
			list.push(command);
			categories.set(category, list);
		}
		for (category in categories.keys())
		{
			Logger.log("{blue}-- " + category + " --{end}");
			var list = categories.get(category);
			list.sort(function(a:CommandCall, b:CommandCall):Int {
                var aName = a.aliases[0];
                var bName = b.aliases[0];
				return (aName > bName ? 1 : (aName < bName ? -1 : 0));
			});
			for (command in list)
			{
				Logger.log('    helm {yellow}${command.aliases[0]}{end} ${command.helpText}');
			}
			Logger.log();
		}
	}

	static var _commands = new Array<CommandCall>();
    static var _aliases = new StringMap<CommandCall>();
}
