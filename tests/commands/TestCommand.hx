package commands;

import utest.Assert;
import helm.Helm;
import haxe.io.BytesOutput;
import helm.util.Logger;
import utest.Test;

class TestCommand extends Test
{
    var output:BytesOutput;

    public function setup()
    {
        output = new BytesOutput();
        Helm.logger = new Logger(output, Verbose, false);
        // Helm.repository = new HaxelibRepo();
    }

    public function assertLogged(log:String)
    {
        Assert.equals(log, output.getBytes().toString());
    }
}
