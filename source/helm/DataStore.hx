package helm;

import sys.db.*;
import helm.ds.Types;

class DataStore
{
	public function new(?path:String)
	{
		if (path == null)
		{
			path = Config.globalPath + "packages.sqlite";
		}
		_db = Sqlite.open(path);
		_db.request("CREATE TABLE IF NOT EXISTS packages (
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
			name TEXT,
			description TEXT,
			owner TEXT,
			license TEXT,
			website TEXT
		)");
		_db.request("CREATE TABLE IF NOT EXISTS tags (
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
			package_id INTEGER,
			name TEXT
		)");
		_db.request("CREATE TABLE IF NOT EXISTS versions (
			package_id INTEGER,
			major INTEGER,
			minor INTEGER,
			patch INTEGER,
			prerelease TEXT,
			prerelease_num INTEGER,
			publish_date REAL,
			release_note TEXT
		)");
	}

	public function addPackage(info:ProjectInfo)
	{
		if (!hasPackage(info.name))
		{
			var name = _db.quote(info.name),
				desc = _db.quote(info.description),
				owner = _db.quote(info.owner),
				license = _db.quote(info.license),
				website = _db.quote(info.website);
			_db.request('INSERT INTO packages (name, description, owner, license, website)
				VALUES ($name, $desc, $owner, $license, $website)');
		}

		for (version in info.versions)
		{
			trace(version);
		}
	}

	public function hasPackage(name:String):Bool
	{
		// only check for existence, don't use qualified names
		return _db.request('SELECT 1 FROM packages WHERE name = ' + _db.quote(name)).length > 0;
	}

	private var _db:Connection;
}
