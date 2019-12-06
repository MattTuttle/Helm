package helm;

import helm.util.*;

class Auth {
	public var username(default, null):String;
	public var password(default, null):String;
	public var email(default, null):String;
	public var name(default, null):String;

	public function new() {}

	public function login():Void {
		while (true) {
			username = Helm.logger.prompt("Username: ").toLowerCase();
			if (Helm.registry.getUserInfo(username) != null)
				break;
			Helm.logger.log(username + " is not registered.");
			var result = Helm.logger.prompt("Would you like to register it? [y/N] ");
			if (~/^y(es)?$/.match(result.toLowerCase())) {
				register(username);
				break;
			}
		}
		while (true) {
			password = Helm.logger.prompt("Password: ", true);
			if (Helm.registry.checkPassword(username, password))
				break;
			Helm.logger.log("Invalid password.");
		}
	}

	public function register(?name:String):Void {
		var username_regex = ~/^[a-z0-9_-]{3,32}$/;
		var email_regex = ~/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;

		if (name == null) {
			while (true) {
				username = Helm.logger.prompt("Username: ").toLowerCase();

				if (!username_regex.match(username)) {
					Helm.logger.log("Invalid username. Must be alphanumeric and 3-32 characters long.");
				} else if (Helm.registry.getUserInfo(username) != null) {
					Helm.logger.log("Username " + username + " is already taken");
				} else {
					break;
				}
			}
		} else {
			username = name;
		}

		while (true) {
			password = Helm.logger.prompt("Password: ", true);
			var confirm = Helm.logger.prompt("Confirm Password: ", true);
			if (password == confirm)
				break;
			Helm.logger.log("Passwords didn't match.");
		}

		while (true) {
			email = Helm.logger.prompt("Email: ");
			if (email_regex.match(email))
				break;
			Helm.logger.log("Invalid email address.");
		}

		name = Helm.logger.prompt("Full Name: ");

		Helm.registry.register(username, password, email, name);
	}
}
