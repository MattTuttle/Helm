import haxe.Timer;
import haxe.io.Bytes;

class DownloadProgress extends haxe.io.Output
{

	public function new(out:haxe.io.Output)
	{
		_fileOutput = out;
		_currentBytes = 0;
		_startTime = Timer.stamp();
	}

	private function round(number:Float, ?precision=2): Float
	{
		var zeroes = Math.pow(10, precision);
		number *= zeroes;
		return Math.round(number) / zeroes;
	}

	private function bytePrettify(bytes:Int):String
	{
		if (bytes < 1024*1024)
			return Std.string(round(bytes / 1024)) + "KB";
		else
			return Std.string(round(bytes / (1024*1024))) + "MB";
	}

	function bytes(numBytes:Int):Void
	{
		_currentBytes += numBytes;
		if (_totalBytes == 0)
		{
			Sys.print(_currentBytes + " bytes\r");
		}
		else
		{
			var percent = _currentBytes / _totalBytes;
			var progressLength = 30;
			var progress = StringTools.rpad(StringTools.lpad(">", "-", Std.int(progressLength * percent)), " ", progressLength);
			Sys.print("Downloading [" + progress + "] " + Std.int(percent * 100) + "% of " + _totalText + "\r");
		}
	}

	public override function writeByte(c):Void
	{
		_fileOutput.writeByte(c);
		bytes(1);
	}

	public override function writeBytes(data:Bytes, position:Int, length:Int):Int
	{
		var bytesWritten = _fileOutput.writeBytes(data, position, length);
		bytes(bytesWritten);
		return bytesWritten;
	}

	public override function close():Void
	{
		super.close();
		_fileOutput.close();

		var time = Timer.stamp() - _startTime;
		var speed = (_currentBytes / time) / 1024;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;
		Sys.print("Download complete: " + bytePrettify(_currentBytes) + " in " + time + "s (" + speed + "KB/s)\n");
	}

	public override function prepare(numBytes:Int):Void
	{
		_totalBytes = numBytes;
		_totalText = bytePrettify(_totalBytes);
	}

	private var _fileOutput:haxe.io.Output;
	private var _currentBytes:Int;
	private var _totalBytes:Int = 0;
	private var _totalText:String;
	private var _startTime:Float;

}
