package helm.ui;

import haxe.ui.toolkit.core.Toolkit;
import haxe.ui.toolkit.core.Root;
import haxe.ui.toolkit.controls.Button;

class Helm
{
	static public function main()
	{
		Toolkit.init();
		Toolkit.openFullscreen(function(root:Root) {
			var button = new Button();
			button.text = "Click Me!";
			root.addChild(button);
		});
	}
}
