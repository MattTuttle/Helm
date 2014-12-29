class Main
{

	static public function main()
	{
		var args = Sys.args();

		var lib = new Haxelib();
		if (args.length < 1)
		{
			lib.usage();
		}
		else
		{
			var command = args.shift();
			lib.process(command, args);
		}
	}

}
