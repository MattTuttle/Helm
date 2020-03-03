package helm;

import helm.ds.PackageInfo;

class Project {
	public function new() {}

	public function getRoot(path:Path):Path {
		var search = path;
		while (search != "") {
			if (FileSystem.isFile(search.join(PackageInfo.JSON))) {
				return search;
			}
			search = search.dirname();
		}

		return path;
	}
}
