package helm.install;

import helm.ds.Ini.IniSection;

interface Installable {
	public final name:String;
	public function install(target:Path, detail:Requirement):Bool;
	public function isInstalled(target:Path):Bool;
	public function freeze(values:IniSection):Void;
	public function thaw(values:IniSection):Void;
}
