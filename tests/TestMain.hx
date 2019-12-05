import haxe.io.BytesOutput;
import utest.Runner;
import utest.ui.Report;
import helm.commands.Search;
import helm.commands.Init;

import helm.Helm;
import helm.util.Logger;

class TestMain
{
	static public function main()
	{
		Helm.logger = new Logger(new BytesOutput());
		Helm.registry = new mocks.MockRegistry();

		var runner = new Runner();

		runner.addCase(new TestRepository());
		runner.addCase(new TestPath());
		runner.addCase(new TestLib());
		runner.addCase(new TestLogging());
		runner.addCase(new TestLocalization());

		// commands
		// runner.addCase(new TestCommand(Init));
		runner.addCase(new TestCommand(Search, ["flixel"]));

		Report.create(runner);
		runner.run();
	}
}
