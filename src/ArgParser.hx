import haxe.ds.StringMap;

class ArgParser
{

	public var current(default, null):String;

	public var complete(get, never):Bool;
	private inline function get_complete():Bool { return !_it.hasNext(); }

	public function new()
	{
		_rules = new StringMap<ArgParser->Void>();
	}

	public function iterator():Iterator<String>
	{
		return _it;
	}

	public function addRule(arg:String, func:ArgParser->Void)
	{
		if (arg == null)
		{
			_defaultHandler = func;
		}
		else
		{
			var rules = arg.split("|");
			for (rule in rules)
			{
				_rules.set(rule, func);
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
			if (_rules.exists(current))
			{
				var func = _rules.get(current);
				func(this);
			}
			else if (_defaultHandler != null)
			{
				_defaultHandler(this);
			}
		}
	}

	private var _it:Iterator<String>;
	private var _defaultHandler:ArgParser->Void;
	private var _rules:StringMap<ArgParser->Void>;

}
