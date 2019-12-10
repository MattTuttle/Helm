package helm.install;

class FilePath implements Installable {
	var path:Path;

	public function new(path:Path) {
		this.path = path;
	}

	public function install(target:Path, name:String):Bool {
		// TODO: create symlink on unix platforms
		FileSystem.copy(this.path, target);
		return true;
	}
}
