package helm.util;

import haxe.ds.StringMap;

typedef ArgParserFunc = ArgParser->Void;
typedef ArgParserRule = {
	func:ArgParserFunc,
	argument:Bool
};

class ArgParser
{

	public var current(default, null):String;
	public var argument(default, null):String;

	public var complete(get, never):Bool;
	private inline function get_complete():Bool { return !_it.hasNext(); }

	public function new()
	{
		_rules = new StringMap<ArgParserRule>();
	}

	public function iterator():Iterator<String>
	{
		return _it;
	}

	public function next():String
	{
		return _it.next();
	}

	public function addRule(func:ArgParserFunc, ?rules:Array<String>, argument:Bool=false)
	{
		if (rules == null)
		{
			_defaultHandler = func;
		}
		else
		{
			for (rule in rules)
			{
				_rules.set(rule, {func: func, argument: argument});
			}
		}
	}

	public function parse(?args:Array<String>):Void
	{
		if (args != null)
		{
			// if (_it != null) throw "Must set args only once";
			_it = args.iterator();
		}
		else if (_it == null) throw "Must set args at least once";

		while (!complete)
		{
			current = _it.next();
			argument = null;

			if (_rules.exists(current))
			{
				var rule = _rules.get(current);
				if (rule.argument)
				{
					if (complete) throw "Expected an argument for " + current;
					argument = _it.next();
				}
				rule.func(this);
			}
			else if (_defaultHandler != null)
			{
				_defaultHandler(this);
			}
		}
	}

	private var _it:Iterator<String>;
	private var _defaultHandler:ArgParserFunc;
	private var _rules:StringMap<ArgParserRule>;

}
