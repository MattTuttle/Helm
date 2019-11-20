import helm.util.ArgParser;
import utest.Test;
import utest.Assert;

class TestArgs extends Test
{

	public function testNoArgs()
	{
		var exceptionThrown = false;
		var a = new ArgParser();
		try
		{
			a.parse();
		}
		catch (e:Dynamic)
		{
			exceptionThrown = true;
		}
		Assert.isTrue(exceptionThrown);
	}

	public function testOrdering()
	{
		var flag = false;
		var a = new ArgParser();
		a.addRule(function(_) { flag = true; }, ["-g"]);

		a.parse(["-g", "ls"]);
		Assert.isTrue(flag);

		flag = false; // reset
		a.parse(["ls", "-g"]);
		Assert.isTrue(flag);

		flag = false; // reset
		a.parse(["ls"]);
		Assert.isFalse(flag);
	}

	public function testMultipleArgsForOneTarget()
	{
		var flag = false;
		var a = new ArgParser();
		a.addRule(function(_) { flag = true; }, ["list", "ls"]);

		a.parse(["ls"]);
		Assert.isTrue(flag);

		flag = false;
		a.parse(["lst"]);
		Assert.isFalse(flag);

		a.parse(["list"]);
		Assert.isTrue(flag);
	}

	public function testContinue()
	{
		var a = new ArgParser();
		a.addRule(function(p:ArgParser) {
			Assert.equals("continue", p.current);
			p.parse();
			Assert.equals("hello", p.current);
		}, ["continue"]);

		a.parse(["continue", "hello"]);
		Assert.equals("hello", a.current);
		Assert.isTrue(a.complete);
	}

	public function testArguments()
	{
		var a = new ArgParser();
		a.addRule(function(p:ArgParser) {
			Assert.equals("filename", p.argument);
		}, ['-o'], true);
		a.parse(['dostuff', '-o', 'filename']);

		var exceptionThrown = false;
		try
		{
			a.parse(['hi', '-o']);
		}
		catch (e:Dynamic)
		{
			exceptionThrown = true;
		}
		Assert.isTrue(exceptionThrown);
	}

}
