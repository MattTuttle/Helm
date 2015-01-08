import haxe.ds.StringMap;
import sys.io.File;

class L10n
{

	static public function init(language:String = "en-us")
	{
		_strings = new StringMap<String>();

		var content = File.getContent("l10n/" + language + "/strings.xml");
		var root = Xml.parse(content).firstElement();
		for (string in root.elements())
		{
			_strings.set(string.get("key"), string.firstChild().toString());
		}
	}

	static public function get(key:String, ?args:Array<Dynamic>):String
	{
		var value = null;
		var reg = ~/\$([0-9]+)/g;
		if (_strings.exists(key))
		{
			value = _strings.get(key);
			while (reg.match(value))
			{
				var index = Std.parseInt(reg.matched(1)) - 1;
				if (index >= 0 && args != null && index < args.length)
				{
					value = reg.matchedLeft() + Std.string(args[index]) + reg.matchedRight();
				}
				else
				{
					throw "Expected argument for " + reg.matched(0);
				}
			}
		}
		return value;
	}

	static private var _strings:StringMap<String>;

}
