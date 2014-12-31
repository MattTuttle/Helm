class TestLib extends haxe.unit.TestCase
{
	public function testPackageInfo()
	{
		assertTrue(Commands.info(["format"]));
	}

	public function testHumanizeBytes()
	{
		assertEquals("860B", DownloadProgress.humanizeBytes(860));
		assertEquals("356KB", DownloadProgress.humanizeBytes(1024*356));
		assertEquals("13.89MB", DownloadProgress.humanizeBytes(14562748));
		assertEquals("1.44GB", DownloadProgress.humanizeBytes(1543862953));
	}
}
