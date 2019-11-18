import helm.Path;

class TestPath extends haxe.unit.TestCase
{
	public function testWindowsBasename()
	{
		var path:Path = 'C:\\temp\\myfile.html';
		assertEquals('myfile.html', path.basename());
	}

    public function testPosixBasename()
	{
		var path:Path = '/home/user/myfile.html';
		assertEquals('myfile.html', path.basename());
	}

    public function testBasenameExtension()
    {
        var path:Path = '/home/user/myfile.html';
        assertEquals('myfile', path.basename('.html'));
		assertEquals('myfile.html', path.basename('.foo'));
    }

	public function testDirname()
	{
		var path:Path = '/usr/local/bin/command';
		assertEquals('/usr/local/bin', path.dirname());
	}

	public function testDelimeter()
	{
		var path:Path = 'D:\\windows\\config.ini';
		assertEquals('\\', path.delimeter);
	}

	public function testNormalizeDuplicateDelimeters()
	{
		var path:Path = 'F:\\\\hi';
		assertEquals('F:\\hi', path.normalize());
		path = '//test/more///than/one/';
		assertEquals('/test/more/than/one/', path.normalize());
	}

	public function testNormalizeDots()
	{
		var path:Path = '/foo/skip/../bar';
		assertEquals('/foo/bar', path.normalize());
		path = 'C:\\files\\.\\video.mp4';
		assertEquals('C:\\files\\video.mp4', path.normalize());
		path = './my/path';
		assertEquals('./my/path', path.normalize());
	}

	public function testAppend()
	{
		var path:Path = '/foo/bar';
		assertEquals('/foo/bar/baz', path.join('baz'));
		assertEquals('/foo/bar/source/Class.hx', path.join('source\\Class.hx'));
		// test root path append
		path = '/';
		assertEquals('/usr', path.join('usr'));
	}

}
