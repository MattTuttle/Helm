package helm;

import haxe.crypto.Md5;

class Auth
{

	public var username(default, null):String;
	public var password(default, null):String;
	public var email(default, null):String;
	public var name(default, null):String;

	public function new()
	{

	}

	public function login():Void
	{
		while (true)
		{
			username = Logger.prompt("Username: ").toLowerCase();
			if (!Repository.server.isNewUser(username)) break;
			Logger.log("Username is not registered.");
			// TODO: allow registration?
		}
		while (true)
		{
			password = Md5.encode(Logger.prompt("Password: ", true));
			if (Repository.server.checkPassword(username, password)) break;
			Logger.log("Invalid password.");
		}
	}

	public function register():Void
	{
		var username_regex = ~/^[a-z0-9_-]{3,32}$/;
		var email_regex = ~/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
		while (true)
		{
			username = Logger.prompt("Username: ").toLowerCase();
			if (!username_regex.match(username))
			{
				Logger.log("Invalid username. Must be alphanumeric and 3-32 characters long.");
				continue;
			}

			if (!Repository.server.isNewUser(username))
			{
				Logger.log("Username " + username + " is already taken");
				continue;
			}

			while (true)
			{
				password = Logger.prompt("Password: ", true);
				var confirm = Logger.prompt("Confirm Password: ", true);
				if (password == confirm) break;
				Logger.log("Passwords didn't match.");
			}
			password = Md5.encode(password);

			while(true)
			{
				email = Logger.prompt("Email: ");
				if (email_regex.match(email)) break;
				Logger.log("Invalid email address.");
			}

			name = Logger.prompt("Full Name: ");

			Repository.server.register(username, password, email, name);
			break;
		}
	}

}
