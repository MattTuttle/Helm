package helm.commands;

import argparse.ArgParser;
import argparse.Namespace;

interface Command {
	public function start(parser:ArgParser):Void;
	public function run(args:Namespace):Bool;
}
