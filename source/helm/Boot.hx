package helm;

import helm.ds.*;

/**
 * Boot/Upgrade HELM without requiring anything installed
 */
class Boot {
	static inline private var PACKAGE_NAME:String = "helm";

	static public function main() {
		var result:Int;

		// TODO: if package not found, install it
		var path = try {
			Helm.repository.findPackage(PACKAGE_NAME);
		} catch (e:Dynamic) {
			Config.globalPath.join("libs").join(PACKAGE_NAME);
		};

		// get latest version on server
		var version:SemVer = try {
			Helm.registry.getProjectInfo(PACKAGE_NAME).currentVersion;
		} catch (e:Dynamic) {
			"0.0.0";
		};

		var originalPath:Path = Sys.getCwd();
		Sys.setCwd(path);

		var info = PackageInfo.load(path);
		if (version > info.version) {
			var installer = new Installer();
			installer.install(PACKAGE_NAME + ":" + version, path);
		}

		if (!FileSystem.isFile("helm")) {
			// TODO: don't assume haxe and nekotools are installed
			result = Sys.command("haxe", [
				    "-neko",                     "helm.n",
				    "-main",                  "helm.Helm",
				      "-cp",                     "source",
				"-resource", "l10n/en-US/strings.xml@en-US"
			]);
			result = Sys.command("nekotools", ["boot", "helm.n"]);
			FileSystem.delete("helm.n");
			if (Sys.systemName() == "Windows") {
				result = Sys.command("setx", ["path", '"%path%;$path\\bin\\"']);
			} else {
				if (!FileSystem.isFile("/usr/local/bin/helm")) {
					result = Sys.command("ln", ["-s", path + "helm", "/usr/local/bin/helm"]);
				}
			}
		}

		// run the command through the latest version
		Sys.setCwd(originalPath);
		result = Sys.command(path + "helm", Sys.args());
	}
}
