package commands;
import argparse.ArgParser;
import helm.commands.Search;
import utest.Assert;

class TestSearch extends TestCommand
{
	public function testSearch()
	{
		var search = Type.createEmptyInstance(Search);
		var parser = new ArgParser();
		search.start(parser);
		var result = parser.parse(["flixel"]);
		Assert.isTrue(search.run(result, ""));
		assertLogged("foobar");
	}
}
