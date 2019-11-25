package helm.commands;

import argparse.Namespace;
import argparse.ArgParser;
import helm.ds.SemVer;

@usage("[package[:version]...]")
@alias("i", "isntall")
@category("development")
class Install implements Command
{

    public function start(parser:ArgParser)
    {
        parser.addArgument({flags: 'package'});
    }

	public function run(args:Namespace, path:Path):Bool
	{
		var packages = args.get('package');
		// if no packages are given as arguments, search in local directory for dependencies
		if (packages.length == 0)
		{
			// TODO: fix install git dependency from haxelib.json
			var libs = Helm.repository.findDependencies(path);

			// install libraries found
			for (lib in libs.keys())
			{
				var name = lib;
				var version:String = libs.get(lib);
				// if version is null it's probably a git repository
				if (version != null && SemVer.ofString(version) == null)
				{
					name = libs.get(lib);
				}
				Helm.repository.install(name, version, path);
			}
		}
		else
		{
			// default rule
			for (name in packages)
			{
				var version:SemVer = null;

				// try to split from name@version
				if (name.indexOf("://") == -1)
				{
					var parts = name.split(":");
					if (parts.length == 2)
					{
						version = SemVer.ofString(parts[1]);
						// only use the first part if successfully parsing a version from the second part
						if (version != null) name = parts[0];
					}
				}
				Helm.repository.install(name, version, path);
			}
		}

		return true;
	}
}
