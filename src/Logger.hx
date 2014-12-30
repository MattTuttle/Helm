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

}
