import argparse.ArgParser;
import argparse.Namespace;
import helm.commands.Command;
import helm.Path;
import helm.FileSystem;
import utest.Assert;
import helm.Helm;
import haxe.io.BytesOutput;
import helm.util.Logger;
import utest.Test;

class TestCommand extends Test {
	final klass:Class<Command>;
	final args:Array<String>;
	final path:Path;

	var output:BytesOutput;
	var repoDir:Null<Path>;
	var instance:Command;
	var result:Namespace;

	public function new(klass:Class<Command>, ?args:Array<String>, ?path:Path) {
		this.klass = klass;
		this.path = path == null ? "" : path;
		this.args = args == null ? [] : args;
		super();
	}

	public function setup() {
		repoDir = FileSystem.createTemporary();
		instance = cast(Type.createEmptyInstance(klass), Command);
		var parser = new ArgParser();
		instance.start(parser);
		result = parser.parse(args);

		output = new BytesOutput();
		Helm.logger = new Logger(output, Verbose, false);
		// Helm.repository = new HaxelibRepo();
	}

	public function teardown() {
		FileSystem.delete(repoDir);
	}

	public function testRun() {
		Assert.isTrue(instance.run(result, path));
	}

	public function assertLogged(log:String) {
		Assert.equals(log, output.getBytes().toString());
	}
}
