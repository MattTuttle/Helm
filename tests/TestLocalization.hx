class TestLocalization extends haxe.unit.TestCase
{

	public function testLocale()
	{
		L10n.init();
		assertEquals("Package Hello is not installed", L10n.get("not_installed", ["Hello"]));
	}

}
