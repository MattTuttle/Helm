class TestLocalization extends haxe.unit.TestCase
{

	public function testLocale()
	{
		helm.L10n.init();
		assertEquals("Package Hello is not installed", helm.L10n.get("not_installed", ["Hello"]));
	}

}
