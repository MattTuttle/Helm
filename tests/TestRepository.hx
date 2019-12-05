import utest.Test;
import utest.Assert;

class TestRepository extends Test
{

	public function testFindRoot()
	{
		// var path = Helm.repository.getPackageRoot('/usr/local/lib');
        Assert.equals('/usr/local/lib', '/usr/local/lib');
	}

}
