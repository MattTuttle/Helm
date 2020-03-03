package helm.commands;

import helm.install.Requirement;
import helm.ds.Lockfile;
import argparse.Namespace;
import argparse.ArgParser;

@category("development")
class Lock implements Command {
	public function start(parser:ArgParser) {}

	public function run(args:Namespace, path:Path):Bool {
		var lockfile = new Lockfile();
		for (lib in Helm.repository.installed(path)) {
			var req = new Requirement(lib.name);
			req.version = lib.version;
			lockfile.addRequirement(req);
		}
		lockfile.save(path);
		var lock = Lockfile.load(path);
		trace(lock);
		return true;
	}
}
