import haxe.ds.StringMap;
import sys.io.File;

class L10n
{

	static public function init(locale:String = "en-US")
	{
		_strings = new StringMap<String>();

		var path = Config.helmPath + "l10n/" + locale + "/strings.xml";
		var content = sys.FileSystem.exists(path) ? File.getContent(path) : haxe.Resource.getString("en-US");
		var root = Xml.parse(content).firstElement();
		for (string in root.elements())
		{
			_strings.set(string.get("key"), string.firstChild().toString());
		}
	}

	static public function get(key:String, ?args:Array<Dynamic>):String
	{
		if (_strings == null) init();

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
