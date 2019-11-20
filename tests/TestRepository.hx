import helm.Repository;
import utest.Test;
import utest.Assert;

class TestRepository extends Test
{

	public function testFindRoot()
	{
		var path = Repository.getPackageRoot('/usr/local/lib');
        Assert.equals('/usr/local/lib', path);
	}

}
