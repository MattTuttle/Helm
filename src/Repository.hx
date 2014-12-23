import tools.haxelib.SemVer;
import tools.haxelib.Data;

class Repository extends haxe.remoting.Proxy<tools.haxelib.SiteApi>
{

	// TODO: setup a mirror list for multiple repository servers
	static public var url = "http://lib.haxe.org/";
	static public var apiVersion = "3.0";

	static public var instance(get, never):Repository;
	static private function get_instance():Repository
	{
		return new Repository(haxe.remoting.HttpConnection.urlConnect(url + "api/" + apiVersion + "/index.n").api);
	}

	static public function fileURL(info:ProjectInfos, version:SemVer=null):String
	{
		var versionString:String = null;

		if (version == null)
		{
			versionString = SemVer.ofString(info.curversion);
		}
		else
		{
			for (v in info.versions)
			{
				if (SemVer.ofString(v.name) == version)
				{
					versionString = version;
					break;
				}
			}
		}

		if (versionString != null)
		{
			// files stored on server use commas instead of periods
			versionString = versionString.split(".").join(",");

			// TODO: return this information from the server instead of creating it on the client
			return url + "files/" + apiVersion + "/" + info.name + "-" + versionString + ".zip";
		}
		return null;
	}

}
