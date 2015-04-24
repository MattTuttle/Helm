package helm.http;

import haxe.io.Input;
import haxe.io.Bytes;

class UploadProgress extends Input
{

	public function new(bytes:Bytes)
	{
		_input = new haxe.io.BytesInput(bytes);
		_currentBytes = 0;
		_totalBytes = bytes.length;
	}

	public override function readByte():Int
	{
		var c = _input.readByte();
		printProgress(1);
		return c;
	}

	public override function readBytes(data:Bytes, position:Int, length:Int):Int
	{
		var k = _input.readBytes(data, position, length);
		printProgress(k);
		return k;
	}

	function printProgress(numBytes:Int)
	{
		_currentBytes += numBytes;
		var percent = _currentBytes / _totalBytes;
		var progressLength = 60;
		var progress = StringTools.rpad(StringTools.lpad(">", "-", Std.int(progressLength * percent)), " ", progressLength);
		Logger.log("[" + progress + "] " + Std.int(percent * 100) + "% of " + DownloadProgress.humanizeBytes(_totalBytes) + "\r", false);
	}

	private var _input:Input;
	private var _currentBytes:Int;
	private var _totalBytes:Int;

}
