
class TestMain
{
	static public function main()
	{
		Logger.OUTPUT = false;
		var unit = new haxe.unit.TestRunner();
		unit.add(new TestLib());
		unit.add(new TestSemVer());
		unit.run();
	}
}
