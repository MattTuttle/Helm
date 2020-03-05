package helm;

import argparse.Namespace;
import argparse.ArgParser;
import haxe.ds.StringMap;
import helm.commands.Command;
import haxe.rtti.Meta;
import haxe.CallStack;

class CommandCall {
	public final name:String;
	public final helpText:String = "";
	public final category:Null<String>;
	public final aliases:Array<String>;

	final _command:Command;

	public function start(parser:ArgParser) {
		_command.start(parser);
	}

	public function call(args:Namespace):Bool {
		// wrap in a try/catch; so if the command explodes it can exit gracefully
		try {
			return _command.run(args);
		} catch (e:Dynamic) {
			Helm.logger.log(Std.string(e));
			Helm.logger.log(CallStack.toString(CallStack.exceptionStack()));
		}
		return false;
	}

	public function new(command:Class<Command>) {
		var meta = Meta.getType(command);
		if (meta.usage != null) {
			if (meta.usage.length == 1) {
				var text = meta.usage.shift();
				this.helpText = text == null ? "" : text;
			} else {
				var sep = "\n        ";
				this.helpText += "command\n      {blue}Commands:{end}" + sep + meta.usage.join(sep);
			}
		}
		// grab a list of aliases
		this.aliases = meta.alias == null ? [] : cast meta.alias;
		// get class name from path
		var name = Type.getClassName(command).split('.').pop();
		if (name == null) {
			// TODO: error handling
			this.name = "";
		} else {
			this.name = name;
			// add lowercase name as the first alias
			this.aliases.unshift(name.toLowerCase());
		}
		// set the category, if any
		this.category = meta.category.shift();
		// create an instance of the class and store it for later calls
		this._command = Type.createEmptyInstance(command);
	}
}

class Commands {
	public static function init() {
		CompileTime.importPackage("helm.commands");
		var commands = CompileTime.getAllClasses('helm.commands');
		for (command in commands) {
			addCommand(command);
		}
	}

	static function addCommand(command:Class<Command>) {
		var command = new CommandCall(command);
		_commands.push(command);
		for (alias in command.aliases) {
			_aliases.set(alias, command);
		}
	}

	public static function getCommand(name:String):Null<CommandCall> {
		return _aliases.get(name);
	}

	static function sortCommandCall(a:CommandCall, b:CommandCall):Int {
		var aName = a.aliases[0];
		var bName = b.aliases[0];
		return (aName > bName ? 1 : (aName < bName ? -1 : 0));
	}

	public static function print():Void {
		var categories = new StringMap<Array<CommandCall>>();
		for (command in _commands) {
			var category = command.category;
			var list = [];
			if (category != null) {
				var catList = categories.get(category);
				if (catList != null) {
					list = catList;
				}
				categories.set(category, list);
			}
			list.push(command);
		}
		for (category in categories.keys()) {
			Helm.logger.log("{blue}-- " + category + " --{end}");
			var list = categories.get(category);
			if (list != null) {
				list.sort(sortCommandCall);
				for (command in list) {
					Helm.logger.log('    helm {yellow}${command.aliases[0]}{end} ${command.helpText}');
				}
				Helm.logger.log();
			}
		}
	}

	static var _commands = new Array<CommandCall>();
	static var _aliases = new StringMap<CommandCall>();
}
