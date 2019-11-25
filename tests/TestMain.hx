import haxe.io.BytesOutput;
import haxe.io.Output;
import utest.Runner;
import utest.ui.Report;
import commands.TestSearch;

import helm.Helm;
import helm.util.Logger;

class TestMain
{
	static public function main()
	{
		Helm.logger = new Logger(new BytesOutput());

		var runner = new Runner();
		runner.addCase(new TestRepository());
		runner.addCase(new TestPath());
		runner.addCase(new TestLib());
		runner.addCase(new TestLogging());
		runner.addCase(new TestSearch());
		runner.addCase(new TestLocalization());
		Report.create(runner);
		runner.run();
	}
}
