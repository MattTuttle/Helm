import haxe.io.BytesOutput;
import helm.util.Logger;
import utest.Test;
import utest.Assert;

class TestLogging extends Test
{

	public function testLogLevel()
	{
		var bytes = new BytesOutput();
        var logger = new Logger(bytes);
        logger.log("hello", LogLevel.Verbose);
		Assert.equals("hello\n", bytes.getBytes().toString());
	}

}
