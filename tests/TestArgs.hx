import helm.ArgParser;

class TestArgs extends haxe.unit.TestCase
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
		assertTrue(exceptionThrown);
	}

	public function testOrdering()
	{
		var flag = false;
		var a = new ArgParser();
		a.addRule(function(_) { flag = true; }, ["-g"]);

		a.parse(["-g", "ls"]);
		assertTrue(flag);

		flag = false; // reset
		a.parse(["ls", "-g"]);
		assertTrue(flag);

		flag = false; // reset
		a.parse(["ls"]);
		assertFalse(flag);
	}

	public function testMultipleArgsForOneTarget()
	{
		var flag = false;
		var a = new ArgParser();
		a.addRule(function(_) { flag = true; }, ["list", "ls"]);

		a.parse(["ls"]);
		assertTrue(flag);

		flag = false;
		a.parse(["lst"]);
		assertFalse(flag);

		a.parse(["list"]);
		assertTrue(flag);
	}

	public function testContinue()
	{
		var a = new ArgParser();
		a.addRule(function(p:ArgParser) {
			assertEquals("continue", p.current);
			p.parse();
			assertEquals("hello", p.current);
		}, ["continue"]);

		a.parse(["continue", "hello"]);
		assertEquals("hello", a.current);
		assertTrue(a.complete);
	}

	public function testArguments()
	{
		var a = new ArgParser();
		a.addRule(function(p:ArgParser) {
			assertEquals("filename", p.argument);
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
		assertTrue(exceptionThrown);
	}

}
