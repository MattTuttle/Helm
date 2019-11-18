package helm;

import sys.db.*;
import helm.ds.Types;
import helm.ds.SemVer;

class DataStore
{

	public function new(?path:Path)
	{
		if (path == null)
		{
			path = Config.globalPath.join("packages.sqlite");
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
		var packageId:Int;
		if (!hasPackage(info.name))
		{
			var name = _db.quote(info.name),
				desc = _db.quote(info.description),
				owner = _db.quote(info.owner),
				license = _db.quote(info.license),
				website = _db.quote(info.website);
			_db.request('INSERT INTO packages (name, description, owner, license, website)
				VALUES ($name, $desc, $owner, $license, $website)');
			packageId = _db.lastInsertId();
		}
		else
		{
			var res = _db.request('SELECT id FROM packages WHERE name = ' + _db.quote(info.name));
			packageId = res.getIntResult(0);
		}

		for (version in info.versions)
		{
			if (!hasVersion(info.name, version.value))
			{
				addVersion(packageId, version);
			}
		}
	}

	public function findPackage(name:String)
	{
		// _db.request('SELECT name')
	}

	public function hasVersion(name:String, version:SemVer):Bool
	{
		return _db.request('SELECT 1 FROM versions v
			INNER JOIN packages p
				ON p.id = v.package_id
				AND p.name = ' + _db.quote(name) + '
			WHERE v.major = ${version.major}
			AND v.minor = ${version.minor}
			AND v.patch = ${version.patch}
			AND v.prerelease = "${version.preRelease}"
			AND v.prerelease_num = ${version.preReleaseNum}').length > 0;
	}

	public function hasPackage(name:String):Bool
	{
		// only check for existence, don't use qualified names
		return _db.request('SELECT 1 FROM packages WHERE name = ' + _db.quote(name)).length > 0;
	}

	private function addVersion(packageId:Int, version:VersionInfo)
	{
		var v = version.value,
			date = _db.quote(version.date.toString()),
			note = _db.quote(version.comments);
		_db.request('INSERT INTO versions
			VALUES ($packageId, ${v.major}, ${v.minor}, ${v.patch}, "${v.preRelease}", ${v.preReleaseNum}, $date, $note)');
	}

	private var _db:Connection;

}
