package helm;

import sys.FileSystem;
import sys.io.File;

using StringTools;

class LibBundle {
	static private function readIgnoreFile(path:String):Array<String> {
		if (FileSystem.exists(path)) {
			var ignoreFile = File.getContent(path);
			var rules = new Array<String>();
			for (line in ignoreFile.split("\n")) {
				if (line.trim() != "" && !line.startsWith("#")) {
					rules.push(line);
				}
			}
			return rules;
		}
		return null;
	}

	static private function addBundleEntries(path:Path, list:List<haxe.zip.Entry>, ignore:EReg, fileName:String = ""):Void {
		for (file in FileSystem.readDirectory(path.join(fileName))) {
			if (ignore.match(file))
				continue;
			var name = fileName + file;
			var filePath = path + name;
			if (FileSystem.isDirectory(filePath)) {
				if (!ignore.match(name + "/")) {
					addBundleEntries(path, list, ignore, name + "/");
				}
			} else {
				// var stat = FileSystem.stat(filePath);
				var bytes = File.read(filePath, true).readAll();
				var entry = {
					fileTime: Date.now(),
					fileSize: bytes.length,
					fileName: name,
					extraFields: null,
					dataSize: 0,
					data: bytes,
					crc32: haxe.crypto.Crc32.make(bytes),
					compressed: false
				};
				haxe.zip.Tools.compress(entry, 9);
				list.push(entry);
			}
		}
	}

	static public function make(path:String):String {
		var info = helm.ds.PackageInfo.load(path);
		if (info == null)
			throw "Not in a package";
		var rules = readIgnoreFile(path + ".helmignore");
		if (rules == null) {
			rules = readIgnoreFile(path + ".gitignore");
			if (rules == null) {
				rules = [];
			}
		}

		// TODO: allow for include lines "!"
		var zipName = info.name + "_" + info.version + ".zip";
		rules.push(info.name + "_*.zip"); // ignore past bundle versions
		rules.push(".git*");
		rules.push("svn/");

		var ignore = new EReg("(" + rules.join("|").replace(".", "\\.").replace("*", ".*") + ")", "ig");

		var entries = new List<haxe.zip.Entry>();
		var zip = File.write(zipName, true);
		var writer = new haxe.zip.Writer(zip);
		addBundleEntries(path, entries, ignore);
		writer.write(entries);
		return zipName;
	}
}
