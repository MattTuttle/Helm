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

	static public function log(msg:String="", newLine:Bool=true, ?level:LogLevel)
	{
		if (level == null) level = Info;

		if (OUTPUT)
		{
			if (newLine)
			{
				Sys.println(msg.rpad(" ", 80));
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
		for (item in array)
		{
			col += maxLength;
			if (col > 80)
			{
				log();
				col = maxLength;
			}
			log(item.rpad(" ", maxLength), false);
		}
		if (col > 0) log(); // add newline, if not at beginning of line
	}

}
