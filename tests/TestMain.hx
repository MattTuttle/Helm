class TestMain
{
	static public function main()
	{
		helm.util.Logger.OUTPUT = false;

		var unit = new haxe.unit.TestRunner();
		unit.add(new TestArgs());
		unit.add(new TestLib());
		unit.add(new TestSemVer());
		unit.add(new TestLocalization());
		unit.add(new TestDataStore());
		unit.run();
	}
}
