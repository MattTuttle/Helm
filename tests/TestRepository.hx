import helm.Repository;
import helm.io.FileSystem;
import utest.Test;
import utest.Assert;

@:access(helm.io.FileSystem)
class TestRepository extends Test
{

	public function testFindRoot()
	{
		FileSystem.addFile("/usr/local/haxelib.json", "foobar");
		var path = Repository.getPackageRoot('/usr/local/lib');
        Assert.equals('/usr/local/lib', path);
	}

}
