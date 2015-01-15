package helm;

class Auth
{

	public var username(default, null):String;
	public var password(default, null):String;
	public var email(default, null):String;
	public var name(default, null):String;

	public function new() { }

	public function login():Void
	{
		while (true)
		{
			username = Logger.prompt("Username: ").toLowerCase();
			if (Repository.server.getUserInfo(username) != null) break;
			Logger.log(username + " is not registered.");
			var result = Logger.prompt("Would you like to register it? [y/N] ");
			if (~/^y(es)?$/.match(result.toLowerCase()))
			{
				register(username);
				break;
			}
		}
		while (true)
		{
			password = Logger.prompt("Password: ", true);
			if (Repository.server.checkPassword(username, password)) break;
			Logger.log("Invalid password.");
		}
	}

	public function register(?name:String):Void
	{
		var username_regex = ~/^[a-z0-9_-]{3,32}$/;
		var email_regex = ~/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;

		if (name == null)
		{
			while (true)
			{
				username = Logger.prompt("Username: ").toLowerCase();

				if (!username_regex.match(username))
				{
					Logger.log("Invalid username. Must be alphanumeric and 3-32 characters long.");
				}
				else if (Repository.server.getUserInfo(username) != null)
				{
					Logger.log("Username " + username + " is already taken");
				}
				else
				{
					break;
				}
			}
		}
		else
		{
			username = name;
		}

		while (true)
		{
			password = Logger.prompt("Password: ", true);
			var confirm = Logger.prompt("Confirm Password: ", true);
			if (password == confirm) break;
			Logger.log("Passwords didn't match.");
		}

		while (true)
		{
			email = Logger.prompt("Email: ");
			if (email_regex.match(email)) break;
			Logger.log("Invalid email address.");
		}

		name = Logger.prompt("Full Name: ");

		Repository.server.register(username, password, email, name);
	}

}
