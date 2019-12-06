import helm.util.L10n;
import utest.Test;
import utest.Assert;

class TestLocalization extends Test {
	public function testLocale() {
		L10n.init("en-US");
		Assert.equals("Package Hello is not installed", L10n.get("not_installed", ["Hello"]));
	}
}
