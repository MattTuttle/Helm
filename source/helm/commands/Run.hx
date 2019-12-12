package helm.commands;

import helm.util.L10n;
import helm.ds.PackageInfo;
import argparse.Namespace;
import argparse.ArgParser;

@usage("[--haxelib] package [args...]")
@category("development")
class Run implements Command {
	public function start(parser:ArgParser):Void {
		parser.addArgument({flags: "--haxelib"});
		parser.addArgument({flags: "package", numArgs: 1});
		parser.addArgument({flags: "args", numArgs: '*'});
	}

	public function run(args:Namespace, path:Path):Bool {
		var name = args.get("package").shift();
		if (name != null) {
			var code = if (args.exists("haxelib")) {
				var arguments = ["run", name];

				Sys.command("haxelib", arguments.concat(args.get("args")));
			} else {
				var useEnvironment = args.exists("env");

				var path = Helm.repository.findPackage(name);
				if (path != null) {
					exec(args.get("args"), path, useEnvironment);
				} else {
					1; // return code when no path is found
				}
			}
			Sys.exit(code);
		}

		return true;
	}

	function exec(args:Array<String>, path:Path, useEnvironment:Bool = false):Int {
		var info = PackageInfo.load(path);
		if (info == null) {
			Helm.logger.log(L10n.get("not_a_package"));
			return 1;
		}

		var command:String;
		if (info.mainClass != null) {
			command = "haxe";
			// TODO: fix this for git and path dependencies
			for (name in info.dependencies) {
				args.push("-lib");
				args.push(name);
			}
			args.unshift(info.mainClass);
			args.unshift("--run");
		} else {
			command = "neko";
			if (!FileSystem.isFile(path.join("run.n"))) {
				Helm.logger.log(L10n.get("run_not_enabled", [info.name]));
				return 1;
			} else {
				args.unshift("run.n");
			}
		}

		if (useEnvironment) {
			Sys.putEnv("HAXELIB_RUN", Sys.getCwd());
		} else {
			args.push(Sys.getCwd());
			Sys.putEnv("HAXELIB_RUN", "1");
		}

		var originalPath = Sys.getCwd();
		Sys.setCwd(path);
		var result = Sys.command(command, args);
		Sys.setCwd(originalPath);
		return result;
	}
}
