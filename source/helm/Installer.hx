package helm;

import haxe.Http;
import sys.io.File;
import helm.ds.SemVer;
import helm.util.L10n;
import helm.ds.Types.VersionInfo;
import helm.ds.Types.ProjectInfo;
import helm.ds.PackageInfo;
import helm.http.DownloadProgress;

using StringTools;

enum InstallType {
	FilePath(path:Path);
	Git(url:String, branch:Null<String>);
	Haxelib;
}

typedef InstallDetail = {
	name:String,
	original:String,
	type:InstallType
};

class Installer {
	var versionDir = "helm";

	public function new() {}

	function installGit(name:String, url:String, branch:String, target:Path):Null<Path> {
		Helm.logger.log(L10n.get("installing_package", [name + "@" + url]));

		var tmpDir = FileSystem.createTemporary();
		var path = tmpDir;
		var args = ["clone"];
		if (branch != null) {
			args.push("-b");
			args.push(branch);
		}
		args.push(url);
		args.push(path);
		// TODO: better handling when git not installed
		Sys.command("git", args);
		var info = PackageInfo.load(path);
		if (info == null) {
			FileSystem.delete(tmpDir);
			Helm.logger.error(L10n.get("not_a_package"));
		} else {
			var installPath = getInstallPath(target, info.name);
			moveToRepository(path, installPath.join(versionDir));
			return installPath;
		}
		return null;
	}

	function getInstallPath(target:Path, name:String) {
		return target.join(Repository.LIB_DIR).join(name);
	}

	function moveToRepository(path:Path, installPath:Path) {
		if (FileSystem.isDirectory(installPath)) {
			FileSystem.delete(installPath);
		} else {
			FileSystem.createDirectory(installPath);
		}
		FileSystem.rename(path, installPath);
	}

	function checkInstalled(version:SemVer, target:Path, info:ProjectInfo):Path {
		var dir = getInstallPath(target, info.name);
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

	function saveCurrentFile(dir:Path) {
		File.saveContent(dir.join(".current"), "helm");
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

	function installHaxelib(name:String, version:SemVer, target:Path):Null<Path> {
		var path = null;
		// conflict resolution
		var info = Helm.registry.getProjectInfo(name);
		if (info == null) {
			Helm.logger.error(L10n.get("not_a_package"));
			return null;
		}
		var dir = checkInstalled(version, target, info);

		// TODO: pick the correct version, not just the latest
		var downloadVersion = getLatestVersion(info, version);
		if (downloadVersion == null) {
			Helm.logger.error(L10n.get("version_not_found", [Std.string(version)]));
			return null;
		}
		Helm.logger.log(L10n.get("installing_package", [info.name + ":" + downloadVersion.value]));

		// download if not installing from a local file
		if (path == null) {
			path = download(downloadVersion);
		}

		// TODO: if zip fails to read, redownload or throw an error?
		unpackFile(path, dir.join(versionDir));

		return dir;
	}

	function installDependencies(installDir:Path, target:Path) {
		// install any dependencies
		var info = PackageInfo.load(installDir);
		if (info != null && info.dependencies != null) {
			for (name in info.dependencies.keys()) {
				var version = info.dependencies.get(name);
				// prevent installing a library we already installed (infinite loop)
				install(name, version, target);
			}
		}
	}

	function addToPackageDependencies(name:String, version:String, target:Path):PackageInfo {
		var info = PackageInfo.load(target);
		info.dependencies.set(name, version);
		info.save();
		return info;
	}

	function libraryIsInstalled(name:String, version:SemVer, target:Path):Bool {
		var packages = Helm.repository.findPackagesIn(name, target);
		for (info in packages) {
			if (version == null || info.version == version) {
				return true;
			}
		}
		return false;
	}

	function parsePackageString(@:const install:String):InstallDetail {
		var name = install;
		var type = Haxelib;
		// check if installing from a git url (git+http://mygitserver.com/repo.git)
		if (install.startsWith("git+")) {
			var parts = install.split("#");
			var branch = null;
			if (parts.length > 1)
				branch = parts.pop();
			var url = parts[0].substr(4);
			name = url.substr(url.lastIndexOf("/") + 1).replace(".git", "");
			type = Git(url, branch);
		}
		// check if installing from github (<User>/<Repository>)
		else if (install.split("/").length == 2) {
			var parts = install.split("#");
			var branch = null;
			if (parts.length > 1)
				branch = parts.pop();
			var url = "https://github.com/" + parts[0] + ".git";
			name = parts[0].split("/").pop();
			type = Git(url, branch);
		}
		// check if installing from a path (C:\User\mypackage)
		else if (FileSystem.isDirectory(install)) {
			var info = PackageInfo.load(install);
			if (info != null) {
				name = info.name;
				type = FilePath(install);
			}
		}

		return {
			name: name,
			original: install,
			type: type
		}
	}

	function installFromFileSystem(name:String, path:Path, target:Path):Null<Path> {
		// TODO: copy folder and check dependencies instead of setting it as a dev directory
		var installDir = getInstallPath(target, name);
		FileSystem.createDirectory(installDir);
		File.saveContent(installDir.join(".dev"), path);
		return installDir;
	}

	function installFromType(detail:InstallDetail, version:SemVer, baseRepo:Path):Bool {
		var path:Path = switch (detail.type) {
			case FilePath(path):
				installFromFileSystem(detail.name, path, baseRepo);
			case Git(url, branch):
				installGit(detail.name, url, branch, baseRepo);
			case Haxelib:
				installHaxelib(detail.name, version, baseRepo);
		}

		// check if something was installed
		if (path == null) {
			Helm.logger.error("Could not install package " + detail.name);
			return false;
		}

		saveCurrentFile(path);
		addToPackageDependencies(detail.name, detail.original, baseRepo);
		installDependencies(path, baseRepo);
		return true;
	}

	public function install(packageInstall:String, ?version:SemVer, ?target:Path):Bool {
		final path = target == null ? Config.globalPath : target;
		var detail = parsePackageString(packageInstall);
		if (!libraryIsInstalled(detail.name, version, path)) {
			return installFromType(detail, version, path);
		}
		return false;
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

	public function download(version:VersionInfo):String {
		var filename = version.url.split("/").pop();
		var cacheFile = Config.cachePath.join(filename);

		// TODO: allow to redownload with --force argument
		if (!FileSystem.isFile(cacheFile)) {
			FileSystem.createDirectory(Config.cachePath);
			// download as different name to prevent loading partial downloads if cancelled
			var downloadPath = cacheFile.replace("zip", "part");

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
