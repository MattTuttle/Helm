import helm.*;
import helm.util.*;
import helm.http.*;

class TestLib extends haxe.unit.TestCase
{
	public function testPackageInfo()
	{
		var parser = new ArgParser();
		parser.parse(["format"]);
		assertTrue(Commands.info(parser));
	}

	public function testHumanizeBytes()
	{
		assertEquals("860B", DownloadProgress.humanizeBytes(860));
		assertEquals("356KB", DownloadProgress.humanizeBytes(1024*356));
		assertEquals("13.89MB", DownloadProgress.humanizeBytes(14562748));
		assertEquals("1.44GB", DownloadProgress.humanizeBytes(1543862953));
	}
}
