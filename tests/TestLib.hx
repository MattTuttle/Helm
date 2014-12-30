class TestLib extends haxe.unit.TestCase
{
	public function testPackageInfo()
	{
		assertTrue(Commands.info(["format"]));
	}
}
