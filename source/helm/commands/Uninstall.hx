package helm.commands;

import helm.util.L10n;
import argparse.Namespace;
import argparse.ArgParser;

@category("development")
@alias("rm", "remove")
class Uninstall implements Command
{
    public function start(parser:ArgParser):Void
    {
        parser.addArgument({flags: "packages"});
    }

    public function run(args:Namespace, path:Path):Bool
    {
        for (packageName in args.get("packages"))
        {
            var infos = Helm.repository.findPackageIn(packageName, path);
            if (infos.length > 0)
            {
                var path:String = null;
                // TODO: should this only delete from the immediate libs folder instead of searching for a package and accidentally deleting a dependency?
                for (info in infos)
                {
                    if (path == null || info.path.length < path.length)
                    {
                        path = info.path;
                    }
                }
                new Directory(path).delete();
                Helm.logger.log(L10n.get("directory_deleted", [packageName]));
            }
        }
        return true;
    }
}
