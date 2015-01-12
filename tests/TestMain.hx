
class TestMain
{
	static public function main()
	{
		Logger.OUTPUT = false;
		Config.load();

		var unit = new haxe.unit.TestRunner();
		unit.add(new TestArgs());
		unit.add(new TestLib());
		unit.add(new TestSemVer());
		unit.add(new TestLocalization());
		unit.run();
	}
}
