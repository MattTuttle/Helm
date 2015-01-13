package helm;

import helm.ds.SemVer;

/**
 * Boot/Upgrade HELM without requiring anything installed
 */
class Boot
{

	static inline private var PACKAGE_NAME:String = "helm";

	static public function main()
	{
		var result:Int;

		Config.load();
		// TODO: if package not found, install it
		var path = try {
			Repository.findPackage(PACKAGE_NAME);
		} catch (e:Dynamic) {
			Config.globalPath + "libs/helm/";
		}
		var info = Repository.loadPackageInfo(path);

		var version:SemVer = try {
			Repository.server.getProjectInfo(PACKAGE_NAME).currentVersion;
		} catch (e:Dynamic) {
			"0.0.0";
		}

		Sys.setCwd(path);

		if (version > info.version)
		{
			Repository.install(PACKAGE_NAME, version, path);
		}

		if (!sys.FileSystem.exists("helm"))
		{
			result = Sys.command("haxe", ["-neko", "helm.n", "-main", "Helm", "-cp", "src"]);
			result = Sys.command("nekotools", ["boot", "helm.n"]);
			sys.FileSystem.deleteFile("helm.n");
		}

		result = Sys.command(path + "helm", Sys.args());
	}
}
