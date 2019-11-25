package helm.commands;

import helm.ds.SemVer;
import helm.util.L10n;
import helm.util.Logger;
import helm.ds.PackageInfo;
import argparse.ArgParser;
import argparse.Namespace;

@usage("[package[:version]...]")
@category("information")
class Info implements Command
{
    public function start(parser:ArgParser):Void
    {
        parser.addArgument({flags: 'packages'});
    }

	public function run(args:Namespace, path:Path):Bool
	{
        var packages = args.get('packages');
		if (packages.length == 0)
		{
			var path = Repository.getPackageRoot(Sys.getCwd());
			var info = PackageInfo.load(path);
			if (info == null)
			{
				Logger.error(L10n.get("not_a_package"));
			}

			Logger.log(info.fullName);
		}
		else
		{
			for (arg in packages)
			{
				var parts = arg.split(":");
				var info = Repository.server.getProjectInfo(parts[0]);
				if (info == null)
				{
					Logger.error(L10n.get("not_a_package"));
				}

				Logger.log(info.name + " [" + info.website + "]");
				Logger.log(info.description);
				Logger.log();
				Logger.log(L10n.get("info_owner", [info.owner]));
				Logger.log(L10n.get("info_license", [info.license]));
				Logger.log(L10n.get("info_tags", [info.tags.join(", ")]));
				Logger.log();

				if (parts.length == 2)
				{
					var versions = new Array<String>();
					// TODO: error handling if invalid version passed or if no version is found
					var requestedVersion = SemVer.ofString(parts[1]);
					var found = false;
					for (version in info.versions)
					{
						if (version.value == requestedVersion)
						{
							Logger.log(L10n.get("info_version", [version.value]));
							Logger.log(L10n.get("info_date", [version.date]));
							Logger.log(L10n.get("info_comments", [version.comments]));
							found = true;
							break;
						}
					}
					if (!found)
					{
						Logger.log(L10n.get("version_not_found", [requestedVersion]));
					}
				}
				else
				{
					var versions = new Array<String>();
					for (version in info.versions) { versions.push(version.value); }
					Logger.log(L10n.get("info_versions", [info.currentVersion]));
					Logger.logList(versions, false);
				}
				Logger.log("-----------");
			}
		}

		return true;
	}
}
