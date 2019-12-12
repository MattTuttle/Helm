package helm;

class Auth {
	public var username(default, null):Null<String>;
	public var password(default, null):Null<String>;
	public var email(default, null):Null<String>;
	public var name(default, null):Null<String>;

	public function new() {}

	public function login():Void {
		while (true) {
			var username = Helm.logger.prompt("Username: ");
			if (username != null) {
				username = username.toLowerCase();
				this.username = username;
				if (Helm.registry.getUserInfo(username) != null)
					break;
				Helm.logger.log(username + " is not registered.");
				var result = Helm.logger.prompt("Would you like to register it? [y/N] ");
				if (result != null && ~/^y(es)?$/.match(result.toLowerCase())) {
					register(username);
					break;
				}
			}
		}
		while (true) {
			var password = Helm.logger.prompt("Password: ", true);
			if (password != null) {
				this.password = password;
				var username = this.username;
				if (username != null && Helm.registry.checkPassword(username, password))
					break;
				Helm.logger.log("Invalid password.");
			}
		}
	}

	public function register(?name:String):Void {
		var username_regex = ~/^[a-z0-9_-]{3,32}$/;
		var email_regex = ~/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;

		if (name == null) {
			while (true) {
				var username = Helm.logger.prompt("Username: ");
				if (username != null) {
					username = username.toLowerCase();
					this.username = username;

					if (!username_regex.match(username)) {
						Helm.logger.log("Invalid username. Must be alphanumeric and 3-32 characters long.");
					} else if (Helm.registry.getUserInfo(username) != null) {
						Helm.logger.log("Username " + username + " is already taken");
					} else {
						break;
					}
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
			var email = Helm.logger.prompt("Email: ");
			if (email != null) {
				this.email = email;
				if (email_regex.match(email))
					break;
			}
			Helm.logger.log("Invalid email address.");
		}

		name = Helm.logger.prompt("Full Name: ");

		var user = this.username;
		var pass = this.password;
		var email = this.email;
		var name = this.name;
		if (user != null && pass != null && email != null && name != null) {
			Helm.registry.register(user, pass, email, name);
		}
	}
}
