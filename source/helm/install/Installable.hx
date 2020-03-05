package helm.install;

interface Installable {
	public final name:String;
	public function install(target:Path, detail:Requirement):Bool;
	public function isInstalled():Bool;
}
