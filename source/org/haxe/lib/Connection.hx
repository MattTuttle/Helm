package org.haxe.lib;

class Connection extends haxe.remoting.Proxy<org.haxe.lib.SiteApi>
{
    public function new()
    {
        var cnx = haxe.remoting.HttpConnection.urlConnect(url + "api/" + apiVersion + "/index.n").resolve('api');
        super(cnx);
    }
}
