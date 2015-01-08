using StringTools;

enum LogLevel
{
	Verbose;
	Info;
	Warning;
	Error;
}

class Logger
{

	static public var OUTPUT:Bool = true;
	static public var LEVEL:LogLevel = Info;

	static public function log(msg:String="", newLine:Bool=true, ?level:LogLevel)
	{
		if (level == null) level = Info;

		if (OUTPUT)
		{
			if (newLine)
			{
				Sys.println(msg);
			}
			else
			{
				Sys.print(msg);
			}
		}
	}

	/**
	 * Prints a string list in multiple columns
	 */
	static public function logList(list:Iterable<String>, ascending:Bool = true):Void
	{
		var maxLength = 0, col = 0;
		var array = new Array<String>();
		for (item in list)
		{
			if (item.length > maxLength) maxLength = item.length;
			array.push(item); // copy to array so sorting works...
		}

		maxLength += 2; // add padding

		array.sort(function (a:String, b:String):Int {
			a = a.toLowerCase();
			b = b.toLowerCase();
			if (ascending)
				return (a > b ? 1 : (a < b ? -1 : 0));
			else
				return (a > b ? -1 : (a < b ? 1 : 0));
		});
		var out = "";
		for (item in array)
		{
			col += maxLength;
			if (col > 80)
			{
				out += "\n";
				col = maxLength;
			}
			out += item.rpad(" ", maxLength);
		}
		if (col > 0) out += "\n"; // add newline, if not at beginning of line
		if (OUTPUT) Sys.print(out);
	}

	static public function prompt(msg:String, secure:Bool = false):String
	{
		Logger.log(msg, false);
		if (secure)
		{
			var buffer = new StringBuf(),
				result = null;
			while (true)
			{
				switch (Sys.getChar(false))
				{
					case 3: // Ctrl+C
						Logger.log();
						Sys.exit(1); // cancel
					case 10, 13: // new line
						result = buffer.toString();
						break;
					case c:
						buffer.addChar(c);
				}
			}
			Logger.log("<secure>");
			return result;
		}
		return Sys.stdin().readLine();
	}

}
