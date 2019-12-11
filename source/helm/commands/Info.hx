package helm.commands;

import helm.ds.SemVer;
import helm.util.L10n;
import helm.ds.PackageInfo;
import argparse.ArgParser;
import argparse.Namespace;

@usage("[package[:version]...]")
@category("information")
class Info implements Command {
	public function start(parser:ArgParser):Void {
		parser.addArgument({flags: 'packages'});
	}

	public function run(args:Namespace, path:Path):Bool {
		var packages = args.get('packages');
		if (packages.length == 0) {
			var path = Helm.repository.getPackageRoot(Sys.getCwd());
			var info = PackageInfo.load(path);
			if (info == null) {
				Helm.logger.error(L10n.get("not_a_package"));
			} else {
				Helm.logger.log(info.fullName);
			}
		} else {
			for (arg in packages) {
				var parts = arg.split(":");
				var info = Helm.registry.getProjectInfo(parts[0]);
				if (info == null) {
					Helm.logger.error(L10n.get("not_a_package"));
				}

				Helm.logger.log(info.name + " [" + info.website + "]");
				Helm.logger.log(info.description);
				Helm.logger.log();
				Helm.logger.log(L10n.get("info_owner", [info.owner]));
				Helm.logger.log(L10n.get("info_license", [info.license]));
				Helm.logger.log(L10n.get("info_tags", [info.tags.join(", ")]));
				Helm.logger.log();

				if (parts.length == 2) {
					var versions = new Array<String>();
					// TODO: error handling if invalid version passed or if no version is found
					var requestedVersion = SemVer.ofString(parts[1]);
					var found = false;
					for (version in info.versions) {
						if (version.value == requestedVersion) {
							Helm.logger.log(L10n.get("info_version", [version.value]));
							Helm.logger.log(L10n.get("info_date", [version.date]));
							Helm.logger.log(L10n.get("info_comments", [version.comments]));
							found = true;
							break;
						}
					}
					if (!found) {
						Helm.logger.log(L10n.get("version_not_found", [requestedVersion]));
					}
				} else {
					var versions = new Array<String>();
					for (version in info.versions) {
						versions.push(version.value);
					}
					Helm.logger.log(L10n.get("info_versions", [info.currentVersion]));
					Helm.logger.logList(versions, false);
				}
				Helm.logger.log("-----------");
			}
		}

		return true;
	}
}
