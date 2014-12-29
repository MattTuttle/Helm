class Main
{

	static public function main()
	{
		var args = Sys.args();
		// var args = ["path", "haxepunk"];

		var lib = new HxDep();
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
