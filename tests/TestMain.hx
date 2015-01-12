
class TestMain
{
	static public function main()
	{
		Logger.OUTPUT = false;
		L10n.init();

		var unit = new haxe.unit.TestRunner();
		unit.add(new TestLib());
		unit.add(new TestSemVer());
		unit.add(new TestLocalization());
		unit.run();
	}
}
