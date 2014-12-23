class Main
{

	static public function main()
	{
		// var args = Sys.args();
		var args = ["install", "haxepunk", "2.5.1"];

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
