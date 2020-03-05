package helm.install;

import sys.io.File;
import helm.ds.Ini.IniSection;
import helm.install.Installable;

class Requirement {
	static var versionDir = "helm";

	public var resolved:Null<String>;
	public var integrity:Null<String>;

	var installable:Installable;

	var original:String;

	function new(requirement:String, installable:Installable) {
		original = requirement;
		this.installable = installable;
	}

	public static function fromString(requirement:String):Requirement {
		for (func in [FilePath.fromString, Git.checkGit, Git.checkGithub, Haxelib.fromString]) {
			var result = func(requirement);
			if (result != null) {
				return new Requirement(requirement, result);
			}
		}
		return new Requirement(requirement, new Haxelib(requirement));
	}

	public var name(get, never):String;

	inline function get_name():String {
		return installable.name;
	}

	function saveCurrentFile(dir:Path):Bool {
		if (dir != null && FileSystem.isDirectory(dir)) {
			File.saveContent(dir.dirname().join(".current"), versionDir);
			return true;
		}
		return false;
	}

	public var installPath(get, never):Path;

	inline function get_installPath():Path {
		return Helm.repository.path.join(name).join(versionDir);
	}

	public inline function install():Bool {
		var path = installPath;
		return installable.install(path, this) && saveCurrentFile(path);
	}

	public inline function isInstalled():Bool {
		return installable.isInstalled();
	}

	public inline function thaw(values:IniSection) {
		return installable.thaw(values);
	}

	public inline function freeze(values:IniSection) {
		return installable.freeze(values);
	}

	function toString():String {
		return name;
	}
}
