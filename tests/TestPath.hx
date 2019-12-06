import helm.Path;
import utest.Test;
import utest.Assert;

class TestPath extends Test {
	public function testWindowsBasename() {
		var path:Path = 'C:\\temp\\myfile.html';
		Assert.equals('myfile.html', path.basename());
	}

	public function testPosixBasename() {
		var path:Path = '/home/user/myfile.html';
		Assert.equals('myfile.html', path.basename());
	}

	public function testBasenameExtension() {
		var path:Path = '/home/user/myfile.html';
		Assert.equals('myfile', path.basename('.html'));
		Assert.equals('myfile.html', path.basename('.foo'));
	}

	public function testDirname() {
		var path:Path = '/usr/local/bin/command';
		Assert.equals('/usr/local/bin', path.dirname());
	}

	public function testDelimeter() {
		var path:Path = 'D:\\windows\\config.ini';
		Assert.equals('\\', path.delimeter);
	}

	public function testNormalizeDuplicateDelimeters() {
		var path:Path = 'F:\\\\hi';
		Assert.equals('F:\\hi', path.normalize());
		path = '//test/more///than/one/';
		Assert.equals('/test/more/than/one', path.normalize());
	}

	public function testNormalizeDots() {
		var path:Path = '/foo/skip/../bar';
		Assert.equals('/foo/bar', path.normalize());
		path = 'C:\\files\\.\\video.mp4';
		Assert.equals('C:\\files\\video.mp4', path.normalize());
		path = './my/path';
		Assert.equals('./my/path', path.normalize());
	}

	public function testAppend() {
		var path:Path = '/foo/bar';
		Assert.equals('/foo/bar/baz', path.join('baz'));
		Assert.equals('/foo/bar/source/Class.hx', path.join('source\\Class.hx'));
		// test root path append
		path = '/';
		Assert.equals('/usr', path.join('usr'));
	}
}
