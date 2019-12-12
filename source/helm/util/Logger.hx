package helm.util;

import haxe.io.Output;

using StringTools;

enum LogLevel {
	Verbose;
	Info;
	Warning;
	Error;
}

class Logger {
	public final level:LogLevel;
	public final colorize:Bool;
	public final writer:Output;

	public function new(writer:Output, level:LogLevel = Info, colorize:Bool = true) {
		this.level = level;
		this.colorize = colorize;
		this.writer = writer;
	}

	public function log(msg:String = "", newLine:Bool = true, level:LogLevel = Info) {
		// color escape codes
		var color = ~/\{([a-z]+)\}/g;
		if (colorize) {
			while (color.match(msg)) {
				var escape = switch (color.matched(1)) {
					case "black": "\x1b[30;1m";
					case "red": "\x1b[31;1m";
					case "green": "\x1b[32;1m";
					case "yellow": "\x1b[33;1m";
					case "blue": "\x1b[34;1m";
					case "magenta": "\x1b[35;1m";
					case "cyan": "\x1b[36;1m";
					case "white": "\x1b[37;1m";
					default: "\x1b[0m";
				};
				msg = color.matchedLeft() + escape + color.matchedRight();
			}
		} else {
			msg = color.replace(msg, "");
		}

		if (newLine) {
			msg = msg + "\n";
		}
		writer.writeString(msg);
	}

	/**
	 * Prints a string list in multiple columns
	 * @param list a list/array of strings to print
	 * @ascending which diretion to sort the list
	 */
	public function logList(list:Iterable<String>, ascending:Bool = true):Void {
		var maxLength = 0, col = 0;
		var array = new Array<String>();
		for (item in list) {
			if (item.length > maxLength)
				maxLength = item.length;
			array.push(item); // copy to array so sorting works...
		}

		maxLength += 2; // add padding

		array.sort(function(a:String, b:String):Int {
			a = a.toLowerCase();
			b = b.toLowerCase();
			if (ascending)
				return (a > b ? 1 : (a < b ? -1 : 0));
			else
				return (a > b ? -1 : (a < b ? 1 : 0));
		});
		var out = "";
		for (item in array) {
			col += maxLength;
			if (col > 80) {
				out += "\n";
				col = maxLength;
			}
			out += item.rpad(" ", maxLength);
		}
		if (col > 0)
			out += "\n"; // add newline, if not at beginning of line
		writer.writeString(out);
	}

	/**
	 * Prompts the user for input
	 * @param msg the message to show to the user before asking for input
	 * @param secure whether or not to show user input (default = false)
	 * @return the user input value
	 */
	public function prompt(msg:String, secure:Bool = false, ?defaultValue:String):Null<String> {
		var result:Null<String> = null;
		log(msg, false);
		if (defaultValue != null) {
			log('[$defaultValue] ', false);
		}

		if (secure) {
			var buffer = new StringBuf();
			while (true) {
				switch (Sys.getChar(false)) {
					case 3: // Ctrl+C
						log();
						Sys.exit(1); // cancel
					case 10, 13: // new line
						result = buffer.toString();
						break;
					case c:
						buffer.addChar(c);
				}
			}
			log("<secure>");
		} else {
			result = Sys.stdin().readLine();
		}

		if (defaultValue != null && result.trim() == "") {
			result = defaultValue;
		}

		return result;
	}

	public function error(msg:String) {
		log(msg, true, LogLevel.Error);
		Sys.exit(1);
	}
}
