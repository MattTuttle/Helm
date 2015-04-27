import helm.ds.Types;

class TestDataStore extends haxe.unit.TestCase
{
	public function testCreate()
	{
		var ds = new helm.DataStore();
		ds.addPackage({
			name: "hxpm",
			description: "My test library",
			website: "http://openfl.org/hxpm/",
			owner: "Somebody",
			license: "MIT",
			currentVersion: "1.4.35-alpha.15",
			versions: new Array<VersionInfo>(),
			tags: new List<String>()
		});
		assertTrue(ds.hasPackage("hxpm"));
	}
}
