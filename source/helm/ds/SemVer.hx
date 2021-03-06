package helm.ds;

using Std;

enum PreRelease {
	Alpha;
	Beta;
	ReleaseCandidate;
	None;
}

class SemVerData {
	public final major:Int = -1;
	public final minor:Int = -1;
	public final patch:Int = -1;
	public final preRelease:PreRelease = None;
	public final preReleaseNum:Int = -1;

	inline public function new(?value:String) {
		if (value != null) {
			if (_semVerRegex.match(value)) {
				major = parseInt(_semVerRegex.matched(1));
				minor = parseInt(_semVerRegex.matched(2));
				patch = parseInt(_semVerRegex.matched(3));
				preRelease = switch (_semVerRegex.matched(4)) {
					case "alpha": Alpha;
					case "beta": Beta;
					case "rc": ReleaseCandidate;
					default: None;
				}
				preReleaseNum = parseInt(_semVerRegex.matched(5));
			}
		}
	}

	function parseInt(value:Null<String>):Int {
		if (value != null) {
			var intValue = value.parseInt();
			if (intValue != null) {
				return intValue;
			}
		}
		return -1;
	}

	static var _semVerRegex = ~/^([0-9]+)\.([0-9]+)\.([0-9]+)(?:-(alpha|beta|rc)(?:\.([0-9]+))?)?$/;
}

abstract SemVer(SemVerData) {
	inline function new(data:SemVerData)
		this = data;

	public var major(get, never):Int;

	inline private function get_major():Int {
		return this.major;
	}

	public var minor(get, never):Int;

	inline private function get_minor():Int {
		return this.minor;
	}

	public var patch(get, never):Int;

	inline private function get_patch():Int {
		return this.patch;
	}

	public var preRelease(get, never):PreRelease;

	inline private function get_preRelease():PreRelease {
		return this.preRelease;
	}

	public var preReleaseNum(get, never):Int;

	inline private function get_preReleaseNum():Int {
		return this.preReleaseNum;
	}

	@:op(A == B)
	inline public function equal(other:SemVer):Bool {
		if (this == null)
			return other == null;
		return other != null
			&& this.major == other.major
			&& this.minor == other.minor
			&& this.patch == other.patch
			&& this.preRelease == other.preRelease
			&& this.preReleaseNum == other.preReleaseNum;
	}

	@:op(A != B)
	inline public function notEqual(other:SemVer):Bool {
		return !equal(other);
	}

	@:op(A <= B)
	inline public function lessThanEquals(other:SemVer):Bool {
		return !greaterThan(other);
	}

	@:op(A < B)
	public function lessThan(other:SemVer):Bool {
		if (this.major < other.major)
			return true;
		else if (this.major == other.major) {
			if (this.minor < other.minor)
				return true;
			else if (this.minor == other.minor) {
				if (this.patch < other.patch)
					return true;
				else if (this.patch == other.patch) {
					var result = comparePreRelease(other);
					if (result < 0)
						return true;
					else if (result == 0) {
						if (this.preReleaseNum < other.preReleaseNum)
							return true;
					}
				}
			}
		}
		return false;
	}

	@:op(A >= B)
	inline public function greaterThanEquals(other:SemVer):Bool {
		return !lessThan(other);
	}

	@:op(A > B)
	public function greaterThan(other:SemVer):Bool {
		if (this.major > other.major)
			return true;
		else if (this.major == other.major) {
			if (this.minor > other.minor)
				return true;
			else if (this.minor == other.minor) {
				if (this.patch > other.patch)
					return true;
				else if (this.patch == other.patch) {
					var result = comparePreRelease(other);
					if (result > 0)
						return true;
					else if (result == 0) {
						if (this.preReleaseNum > other.preReleaseNum)
							return true;
					}
				}
			}
		}
		return false;
	}

	private function comparePreRelease(other:SemVer):Int {
		switch (this.preRelease) {
			case Alpha:
				switch (other.preRelease) {
					case Alpha: return 0;
					default: return -1;
				}
			case Beta:
				switch (other.preRelease) {
					case Beta: return 0;
					case Alpha: return 1;
					default: return -1;
				}
			case ReleaseCandidate:
				switch (other.preRelease) {
					case ReleaseCandidate: return 0;
					case null: return -1;
					default: return 1;
				}
			default:
				switch (other.preRelease) {
					case null: return 0;
					default: return 1;
				}
		}
	}

	@:from
	static inline public function ofString(value:String) {
		var data = new SemVerData(value);
		return new SemVer(data);
	}

	@:to
	public function toString():String {
		if (this == null) {
			return "0.0.0";
		} else {
			var out = major + "." + minor + "." + patch;
			out += switch (preRelease) {
				case Alpha: "-alpha";
				case Beta: "-beta";
				case ReleaseCandidate: "-rc";
				case None: "";
			};
			if (preReleaseNum >= 0) {
				out += "." + preReleaseNum;
			}
			return out;
		}
	}
}
