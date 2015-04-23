# Helm

The <u>H</u>axe <u>E</u>xtended <u>L</u>ibrary <u>M</u>anager is an alternative frontend to handle Haxe libraries (like haxelib). HELM shares many of the same commands as haxelib but also has several key differences.

* Locally stored packages (as well as global)
* Zip and publish packages from the project folder
* Dependencies are local to a package
* Single version installed at a time
* Initialize a project and pull in dependencies

### Installing Libraries

Libraries can be installed locally, the default, or globally. Doing so will download the library and unzip it into the appropriate `libs/` folder.

```bash
helm install openfl
# install multiple libraries globally
helm -g install openfl hxcpp
# install from git (alternate shortcut)
helm i https://bitbucket.org/Lythom/haxepunk-gui.git
helm i HaxeFoundation/hxcpp # shortcut for github
# install a specific version
helm i format@3.1.2
```

### Show Installed Libraries

To get a full listing of the installed libraries use the following command.

```bash
# shows libraries installed locally
helm list
# show global libraries (alternate shortcut)
helm ls -g
```

### Building with hxml

Since hxml files require haxelib we need to build using helm instead.

```bash
helm build compile.hxml
```
