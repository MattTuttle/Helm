package helm;

import helm.ds.Types;
import haxe.io.Bytes;

class Server
{
    public function new()
    {

    }

    public function getProjectInfo(name:String):ProjectInfo
    {
        return null;
    }

    public function getUserInfo(username:String):UserInfo
    {
        return null;
    }

    public function register(username:String, password:String, email:String, name:String):Bool
    {
        return false;
    }

    public function checkPassword(username:String, password:String):Bool
    {
        return false;
    }

    public function submit(name:String, data:Bytes, auth:helm.Auth):Void
    {

    }

    public function findProject(name:String):List<{ name : String, id : Int }>
    {
        return new List();
    }
}
