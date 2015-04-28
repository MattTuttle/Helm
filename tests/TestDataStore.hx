import helm.ds.Types;
import helm.ds.SemVer;

class TestDataStore extends haxe.unit.TestCase
{
	public function testCreate()
	{
		var ds = new helm.DataStore();
		var versions = new Array<VersionInfo>();
		versions.push({
			value: SemVer.ofString("0.3.9-beta.53"),
			date: Date.now(),
			url: "",
			comments: ""
		});
		ds.addPackage({
			name: "hxpm",
			description: "My test library",
			website: "http://openfl.org/hxpm/",
			owner: "Somebody",
			license: "MIT",
			currentVersion: "1.4.35-alpha.15",
			versions: versions,
			tags: new List<String>()
		});

		assertTrue(ds.hasPackage("hxpm"));
		assertFalse(ds.hasPackage("haxe"));

		assertTrue(ds.hasVersion("hxpm", "0.3.9-beta.53"));
		assertFalse(ds.hasVersion("hxpm", "1.2.3"));
	}
}
