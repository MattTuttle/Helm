# Helm

<u>H</u>axe <u>E</u>nhanced <u>L</u>ibrary <u>M</u>anager provides recreatable builds, caching, and other benefits on top of haxelib. HELM works *with* haxelib instead of as a replacement. It enhances a Haxe project by providing the following benefits.

* Locally stored packages
* Zip and publish packages from the project folder
* Options for installing packages and dependencies (haxelib, git, local paths)
* Single version of a package installed
* Packages are cached for quick installs
* Initialize a project and pull in dependencies

### Installing Libraries

Libraries can be installed locally, the default, or globally. Doing so will download the library and unzip it into the appropriate `libs/` folder.

```bash
helm add openfl
# install from git (alternate shortcut)
helm add https://bitbucket.org/Lythom/haxepunk-gui.git
helm add HaxeFoundation/hxcpp # shortcut for github
# install from a folder
helm add c:\\Haxe\\mylib
# install a specific version
helm add format:3.1.2
```

### Show Installed Libraries

To get a full listing of the installed libraries use the following command.

```bash
# shows libraries installed locally
helm list
```

### Running commands

Helm can run commands just like haxelib does.

```bash
helm run openfl build html5
# or
helm openfl build html5
```

### Building with hxml

Helm can also build hxml files.

```bash
helm build compile.hxml
# or to build all hxml files in your project
helm build
```
