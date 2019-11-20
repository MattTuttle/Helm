import helm.*;
import helm.util.*;
import helm.http.*;
import utest.Test;
import utest.Assert;

class TestLib extends Test
{
	public function testHumanizeBytes()
	{
		Assert.equals("860B", DownloadProgress.humanizeBytes(860));
		Assert.equals("356KB", DownloadProgress.humanizeBytes(1024*356));
		Assert.equals("13.89MB", DownloadProgress.humanizeBytes(14562748));
		Assert.equals("1.44GB", DownloadProgress.humanizeBytes(1543862953));
	}
}
