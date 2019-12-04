package helm.http;

import haxe.io.Bytes;

class DownloadProgress extends haxe.io.Output
{

	public function new(out:haxe.io.Output)
	{
		_fileOutput = out;
		_currentBytes = 0;
	}

	static public function humanizeBytes(bytes:Int):String
	{
		var byteSuffix = ["B", "KB", "MB", "GB", "TB"];
		var result:Float = bytes, i = 0;
		while (result > 1024 && i < byteSuffix.length - 1)
		{
			result /= 1024;
			i += 1;
		}
		return Math.round(result * 100) / 100 + byteSuffix[i];
	}

	function printProgress(numBytes:Int):Void
	{
		_currentBytes += numBytes;
		if (_totalBytes == 0)
		{
			Helm.logger.log(_currentBytes + " bytes\r", false);
		}
		else
		{
			var percent = _currentBytes / _totalBytes;
			var progressLength = 60;
			var progress = StringTools.rpad(StringTools.lpad(">", "-", Std.int(progressLength * percent)), " ", progressLength);
			Helm.logger.log("[" + progress + "] " + Std.int(percent * 100) + "% of " + _totalText + "\r", false);
		}
	}

	public override function writeByte(byte:Int):Void
	{
		_fileOutput.writeByte(byte);
		printProgress(1);
	}

	public override function writeBytes(data:Bytes, position:Int, length:Int):Int
	{
		var bytesWritten = _fileOutput.writeBytes(data, position, length);
		printProgress(bytesWritten);
		return bytesWritten;
	}

	public override function close():Void
	{
		super.close();
		_fileOutput.close();
		Helm.logger.log();
	}

	public override function prepare(numBytes:Int):Void
	{
		_totalBytes = numBytes;
		_totalText = humanizeBytes(_totalBytes);
	}

	private var _fileOutput:haxe.io.Output;
	private var _currentBytes:Int;
	private var _totalBytes:Int = 0;
	private var _totalText:String;

}
