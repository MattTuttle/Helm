package helm;

import haxe.Http;
import sys.io.File;
import helm.ds.SemVer;
import helm.util.L10n;
import helm.ds.Types.VersionInfo;
import helm.ds.Types.ProjectInfo;
import helm.ds.PackageInfo;
import helm.http.DownloadProgress;
import helm.haxelib.Data;

using StringTools;

class Installer
{

	public function new() {}

	function installGit(name:String, ?target:Path):Bool
	{
		if (target == null) target = Config.globalPath;
		var gitRepository = null,
			gitBranch = null,
			installed = false;

		if (name.startsWith("git+"))
		{
			var parts = name.split("#");
			if (parts.length > 1) gitBranch = parts.pop();
			gitRepository = parts[0].substr(4);
			name = gitRepository.substr(gitRepository.lastIndexOf("/") + 1).replace(".git", "");
		}
		else if (name.split("/").length == 2) // <User>/<Repository>
		{
			var parts = name.split("#");
			if (parts.length > 1) gitBranch = parts.pop();
			gitRepository = "https://github.com/" + parts[0] + ".git";
			name = parts[0].split("/").pop();
		}

		if (gitRepository != null)
		{
			Helm.logger.log(L10n.get("installing_package", [name + "@" + gitRepository]));

			var tmpDir = FileSystem.createTemporary();
			var path = tmpDir;
			var args = ["clone"];
			if (gitBranch != null)
			{
				args.push("-b");
				args.push(gitBranch);
			}
			args.push(gitRepository);
			args.push(path);
			Sys.command("git", args);
			var info = PackageInfo.load(path);
			if (info == null)
			{
				FileSystem.delete(tmpDir);
				Helm.logger.error(L10n.get("not_a_package"));
			}
			else
			{
				// rename folder to the name of the project
				var installPath = target.join(Repository.LIB_DIR).join(info.name);
				if (FileSystem.isDirectory(installPath))
				{
					FileSystem.delete(installPath);
				}
				else
				{
					FileSystem.createDirectory(installPath);
				}
				FileSystem.rename(path, installPath);
				installed = true;
			}
		}
		return installed;
	}

	function checkInstalled(version:SemVer, target:Path, info:ProjectInfo):Path
	{
		var dir = target.join(Repository.LIB_DIR).join(info.name);
		if (FileSystem.isDirectory(dir))
		{
			var info = PackageInfo.load(dir);
			if (info != null && (version == null || version == info.version))
			{
				// TODO: change this to a warning
				Helm.logger.error(L10n.get("already_installed", [info.fullName]));
			}
			else
			{
				FileSystem.delete(dir);
			}
		}
		return dir;
	}

	function unpackFile(zipfile:Path, target:Path)
	{
		var f = File.read(zipfile, true);
		var zip = haxe.zip.Reader.readZip(f);
		f.close();
		var baseDir = locateBasePath(zip);

		var totalItems = zip.length,
			unzippedItems = 0;
		for (item in zip)
		{
			var percent = ++unzippedItems / totalItems;
			var progress = StringTools.rpad(StringTools.lpad(">", "-", Math.floor(60 * percent)), " ", 60);
			Helm.logger.log('[$progress] $unzippedItems/$totalItems\r', false);

			// strip first directory if any
			var path:Path = item.fileName.substr(baseDir.length);
			path = path.normalize();

			var loc = target.join(path);
			FileSystem.createDirectory(loc.dirname(), true);

			var data = haxe.zip.Reader.unzip(item);
			if (data.length > 0)
			{
				File.saveBytes(loc, data);
			}
		}
		Helm.logger.log("\n", false);
	}

	function installDownload(name:String, ?version:SemVer, ?target:Path):Bool
	{
		if (target == null) target = "";
		var path = null;
		// conflict resolution
		var info = Helm.server.getProjectInfo(name);
		if (info == null)
		{
			Helm.logger.error(L10n.get("not_a_package"));
			return false;
		}
		var dir = checkInstalled(version, target, info);

		// TODO: pick the correct version, not just the latest
		var downloadVersion = getLatestVersion(info, version);
		if (downloadVersion == null)
		{
			Helm.logger.error(L10n.get("version_not_found", [Std.string(version)]));
			return false;
		}
		Helm.logger.log(L10n.get("installing_package", [info.name + ":" + downloadVersion.value]));

		// download if not installing from a local file
		if (path == null)
		{
			path = download(downloadVersion);
		}

		// TODO: if zip fails to read, redownload or throw an error?
		var versionDir = "helm";
		var installDir = dir.join(versionDir);
		unpackFile(path, installDir);
		File.saveContent(dir.join(".current"), versionDir);

		// install any dependencies
		var info = PackageInfo.load(installDir);
		if (info != null && info.dependencies != null)
		{
			for (name in info.dependencies.keys())
			{
				var version = info.dependencies.get(name);
				// prevent installing a library we already installed (infinite loop)
				install(name, version, target);
			}
		}
		return true;
	}

	public function install(name:String, ?version:SemVer, ?target:Path):Void
	{
		// check if installing from a local file
		if (FileSystem.isDirectory(name))
		{
			trace(name, " is the path to install");
			// TODO: load project info
		}
		else if (installGit(name, target))
		{
			return;
		}

		installDownload(name, version, target);
	}

	function locateBasePath(zip:List<haxe.zip.Entry>):String
	{
		for (f in zip)
		{
			// find haxelib.json file
			if (StringTools.endsWith(f.fileName, Data.JSON))
			{
				return f.fileName.substr(0, f.fileName.length - Data.JSON.length);
			}
		}
		throw "No " + Data.JSON + " found";
	}

	public function download(version:VersionInfo):String
	{
		var filename = version.url.split("/").pop();
		var cache = Config.cachePath + filename;

		// TODO: allow to redownload with --force argument
		if (!FileSystem.isDirectory(cache))
		{
			FileSystem.createDirectory(Config.cachePath);
			// download as different name to prevent loading partial downloads if cancelled
			var downloadPath = cache.replace("zip", "part");

			// download the file and show progress
			var out = File.write(downloadPath, true);
			var progress = new DownloadProgress(out);
			var http = new Http(version.url);
			http.onError = function(error) {
				progress.close();
			};
			http.customRequest(false, progress);

			// move file from the downloads folder to cache (prevents corrupt zip files if cancelled)
			FileSystem.rename(downloadPath, cache);
		}

		return cache;
	}

	function getLatestVersion(info:ProjectInfo, version:SemVer=null):VersionInfo
	{
		if (version == null)
		{
			// TODO: sort versions?
			for (v in info.versions)
			{
				if (v.value.preRelease == null)
				{
					return v;
				}
			}
		}
		else
		{
			for (v in info.versions)
			{
				if (v.value == version)
				{
					return v;
				}
			}
		}
		return null;
	}

}