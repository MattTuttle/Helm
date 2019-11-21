import utest.Runner;
import utest.ui.Report;

class TestMain
{
	static public function main()
	{
		helm.util.Logger.OUTPUT = false;

		var runner = new Runner();
		runner.addCase(new TestRepository());
		runner.addCase(new TestPath());
		runner.addCase(new TestLib());
		// runner.addCase(new TestSemVer());
		runner.addCase(new TestLocalization());
		Report.create(runner);
		runner.run();
	}
}
