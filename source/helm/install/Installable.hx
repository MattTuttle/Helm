package helm.install;

interface Installable {
	public function install(target:Path, name:String):Bool;
}
