package helm.install;

import haxe.Http;
import helm.http.DownloadProgress;
import helm.ds.Types.ProjectInfo;
import helm.ds.PackageInfo;
import helm.ds.Types.VersionInfo;
import helm.util.L10n;
import helm.ds.SemVer;
import sys.io.File;

using StringTools;

class Haxelib implements Installable {
	var version:SemVer;

	public function new(?version:SemVer) {
		this.version = version;
	}

	public function install(target:Path, name:String):Bool {
		var path = null;
		// conflict resolution
		var info = Helm.registry.getProjectInfo(name);
		if (info == null) {
			Helm.logger.error(L10n.get("not_a_package"));
			return false;
		}
		var dir = checkInstalled(version, target, info);

		// TODO: pick the correct version, not just the latest
		var downloadVersion = getLatestVersion(info, version);
		if (downloadVersion == null) {
			Helm.logger.error(L10n.get("version_not_found", [Std.string(version)]));
			return false;
		}
		Helm.logger.log(L10n.get("installing_package", [info.name + ":" + downloadVersion.value]));

		// download if not installing from a local file
		if (path == null) {
			path = download(downloadVersion);
		}

		// TODO: if zip fails to read, redownload or throw an error?
		unpackFile(path, dir);

		return true;
	}

	public function download(version:VersionInfo):String {
		var filename = version.url.split("/").pop();
		var cacheFile = Config.cachePath.join(filename);

		// TODO: allow to redownload with --force argument
		if (!FileSystem.isFile(cacheFile)) {
			FileSystem.createDirectory(Config.cachePath);
			// download as different name to prevent loading partial downloads if cancelled
			var downloadPath:Path = cacheFile.replace("zip", "part");

			// download the file and show progress
			var out = File.write(downloadPath, true);
			var progress = new DownloadProgress(out);
			var http = new Http(version.url);
			http.onError = (error) -> progress.close();
			http.customRequest(false, progress);

			// move file from the downloads folder to cache (prevents corrupt zip files if cancelled)
			FileSystem.rename(downloadPath, cacheFile);
		}

		return cacheFile;
	}

	function unpackFile(zipfile:Path, target:Path) {
		var f = File.read(zipfile, true);
		var zip = haxe.zip.Reader.readZip(f);
		f.close();
		var baseDir = locateBasePath(zip);

		var totalItems = zip.length, unzippedItems = 0;
		for (item in zip) {
			var percent = ++unzippedItems / totalItems;
			var progress = StringTools.rpad(StringTools.lpad(">", "-", Math.floor(60 * percent)), " ", 60);
			Helm.logger.log('[$progress] $unzippedItems/$totalItems\r', false);

			// strip first directory if any
			var path:Path = item.fileName.substr(baseDir.length);
			path = path.normalize();

			var loc = target.join(path);
			FileSystem.createDirectory(loc.dirname(), true);

			var data = haxe.zip.Reader.unzip(item);
			if (data.length > 0) {
				File.saveBytes(loc, data);
			}
		}
		Helm.logger.log("\n", false);
	}

	function checkInstalled(version:SemVer, target:Path, info:ProjectInfo):Path {
		var dir = Installer.getInstallPath(target, info.name);
		if (FileSystem.isDirectory(dir)) {
			var info = PackageInfo.load(dir);
			if (info != null && (version == null || version == info.version)) {
				// TODO: change this to a warning
				Helm.logger.error(L10n.get("already_installed", [info.fullName]));
			} else {
				FileSystem.delete(dir);
			}
		}
		return dir;
	}

	function locateBasePath(zip:List<haxe.zip.Entry>):String {
		var json = PackageInfo.JSON;
		for (f in zip) {
			// find haxelib.json file
			if (StringTools.endsWith(f.fileName, json)) {
				return f.fileName.substr(0, f.fileName.length - json.length);
			}
		}
		throw "No " + json + " found";
	}

	function getLatestVersion(info:ProjectInfo, version:SemVer = null):VersionInfo {
		if (version == null) {
			// TODO: sort versions?
			for (v in info.versions) {
				if (v.value.preRelease == null) {
					return v;
				}
			}
		} else {
			for (v in info.versions) {
				if (v.value == version) {
					return v;
				}
			}
		}
		return null;
	}
}
