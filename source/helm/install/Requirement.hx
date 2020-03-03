package helm.install;

import helm.install.Installable;

class Requirement {
	public var resolved:Null<String>;
	public var integrity:Null<String>;
	public var dependencies:Null<Array<String>>;

	public var installable:Installable;

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

	public function install(target:Path):Bool {
		return installable.install(target, this);
	}

	function toString():String {
		return installable.name;
	}
}
