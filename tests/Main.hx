
class Main
{
	static public function main()
	{
		var unit = new haxe.unit.TestRunner();
		unit.add(new TestLib());
		unit.run();
	}
}
