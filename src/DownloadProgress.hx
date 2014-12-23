import haxe.Timer;
import haxe.io.Bytes;

class DownloadProgress extends haxe.io.Output
{

	var fileOutput:haxe.io.Output;
	var currentBytes:Int;
	var totalBytes:Int = 0;
	var totalText:String;
	var start:Float;

	public function new(out:haxe.io.Output)
	{
		fileOutput = out;
		currentBytes = 0;
		start = Timer.stamp();
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
		currentBytes += numBytes;
		if (totalBytes == 0)
		{
			Sys.print(currentBytes + " bytes\r");
		}
		else
		{
			var percent = currentBytes / totalBytes;
			var progressLength = 30;
			var progress = StringTools.rpad(StringTools.lpad(">", "-", Std.int(progressLength * percent)), " ", progressLength);
			Sys.print("Downloading [" + progress + "] " + Std.int(percent * 100) + "% of " + totalText + "\r");
		}
	}

	public override function writeByte(c):Void
	{
		fileOutput.writeByte(c);
		bytes(1);
	}

	public override function writeBytes(data:Bytes, position:Int, length:Int):Int
	{
		var bytesWritten = fileOutput.writeBytes(data, position, length);
		bytes(bytesWritten);
		return bytesWritten;
	}

	public override function close():Void
	{
		super.close();
		fileOutput.close();

		var time = Timer.stamp() - start;
		var speed = (currentBytes / time) / 1024;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;
		Sys.print("Download complete: " + bytePrettify(currentBytes) + " in " + time + "s (" + speed + "KB/s)\n");
	}

	public override function prepare(numBytes:Int):Void
	{
		totalBytes = numBytes;
		totalText = bytePrettify(totalBytes);
	}

}
