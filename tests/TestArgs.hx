class TestArgs extends haxe.unit.TestCase
{
	public function testOrdering()
	{
		var flag = false;
		var a = new ArgParser();
		a.addRule("-g", function(_) { flag = true; });

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
		a.addRule("list|ls", function(_) { flag = true; });

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
		a.addRule("continue", function(p:ArgParser) {
			assertEquals(p.current, "continue");
			p.parse();
			assertEquals(p.current, "hello");
		});

		a.parse(["continue", "hello"]);
		assertEquals(a.current, "hello");
		assertTrue(a.complete);
	}
}
