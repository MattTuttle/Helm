package helm;

import helm.ds.*;

/**
 * Boot/Upgrade HELM without requiring anything installed
 */
class Boot
{

	static inline private var PACKAGE_NAME:String = "helm";

	static public function main()
	{
		var result:Int;

		// TODO: if package not found, install it
		var path = try {
			Repository.findPackage(PACKAGE_NAME);
		} catch (e:Dynamic) {
			Config.globalPath + "libs" + Directory.SEPARATOR + PACKAGE_NAME + Directory.SEPARATOR;
		};

		// get latest version on server
		var version:SemVer = try {
			Repository.server.getProjectInfo(PACKAGE_NAME).currentVersion;
		} catch (e:Dynamic) {
			"0.0.0";
		};

		Sys.setCwd(path);

		var info = PackageInfo.load(path);
		if (version > info.version)
		{
			Repository.install(PACKAGE_NAME, version, path);
		}

		if (!sys.FileSystem.exists("helm"))
		{
			// TODO: don't assume haxe and nekotools are installed
			result = Sys.command("haxe", ["-neko", "helm.n",
				"-main", "helm.Helm",
				"-cp", "source",
				"-resource", "l10n/en-US/strings.xml@en-US"
			]);
			result = Sys.command("nekotools", ["boot", "helm.n"]);
			sys.FileSystem.deleteFile("helm.n");
			if (Sys.systemName() == "Windows")
			{
				result = Sys.command("setx", ["path", '"%path%;$path\\bin\\"']);
			}
			else
			{
				result = Sys.command("ln", ["-s", path + "helm", "/usr/local/bin"]);
			}
		}

		// run the command through the latest version
		result = Sys.command(path + "helm", Sys.args());
	}
}
