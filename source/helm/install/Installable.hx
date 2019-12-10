package helm.install;

interface Installable {
	public function install(target:Path, detail:Requirement):Bool;
}
