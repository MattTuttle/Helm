package helm.ds;

import haxe.ds.StringMap;

using StringTools;

@:forward(keys, get)
abstract IniSection(StringMap<String>) {
	public function new() {
		this = new StringMap<String>();
	}

	public function set(name:String, value:Null<String>) {
		var v = value;
		if (v != null)
			this.set(name, v);
	}
}

typedef IniData = StringMap<IniSection>;

@:forward(keys, get, set)
abstract Ini(IniData) from IniData to IniData {
	public function new() {
		this = new IniData();
	}

	@:from static function fromString(data:String):Ini {
		var ini = new IniData();
		var currentSection = new IniSection();
		// would have used ereg but it appears to be broken in hashlink as of 3/2020
		for (line in data.replace("\r", "").split("\n")) {
			line = line.trim();
			if (line.contains("=")) {
				var parts = line.split("=");
				currentSection.set(parts[0].trim(), parts[1].trim());
			} else if (line.startsWith("[")) {
				var name = line.replace("[", "").replace("]", "").trim();
				currentSection = new IniSection();
				ini.set(name, currentSection);
			}
		}
		return ini;
	}

	@:to static function toString(ini:Ini):String {
		var lines = [];
		for (section in ini.keys()) {
			var data = ini.get(section);
			lines.push('[$section]');
			for (key in data.keys()) {
				var value = data.get(key);
				if (value != null)
					lines.push('$key=$value');
			}
			lines.push(""); // empty line
		}
		return lines.join("\n");
	}
}
