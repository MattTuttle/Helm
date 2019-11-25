package helm.commands;

import sys.io.File;
import helm.ds.PackageInfo;
import helm.util.L10n;
import helm.util.Logger;
import argparse.ArgParser;
import argparse.Namespace;

@usage("register [username] [email]", "user username", "submit")
@category("haxelib")
class Haxelib implements Command
{
    public function start(parser:ArgParser):Void
    {
		parser.addArgument({flags: "args"});
    }

	public function run(args:Namespace, path:Path):Bool
	{
		if (args.exists("args"))
		{
			var it = args.get("args").iterator();
			switch (it.next())
			{
				case "register":
					var auth = new Auth();
					auth.register();
				case "user":
					if (!it.hasNext()) return false;

					for (arg in it)
					{
						var user = Repository.server.getUserInfo(arg);
						if (user == null)
						{
							Logger.log(arg + " is not registered.");
						}
						else
						{
							Logger.log(user.fullName + " [" + user.email + "]");
							Logger.log();
							Logger.log(L10n.get("packages"));
							Logger.logList(user.projects);
						}
					}
				case "publish", "upload", "submit":
					var info = PackageInfo.load(path);
					if (info == null)
					{
						Logger.error(L10n.get("not_a_package"));
					}

					var auth = new Auth();
					auth.login();
					var bundleName = LibBundle.make(path);

					Repository.server.submit(info.name, File.read(bundleName).readAll(), auth);
				default:
					return false;
			}
			return true;
		}
		return false;
	}
}
