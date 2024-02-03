import std.process;

/** represents a shell command */
class Command {
	/** command _name */
	string name;
	/** command arguments */
	string[] args;
	/** command _output */
	string output;

	/** creates a new command with the given _name and arguments
	 * Params:
	 * 		name = command name (e.g. "ls")
	 * 		args = command arguments (e.g. ["-l", "-a"])
	 */
	this(string name, string[] args) {
		this.name = name;
		this.args = args;
	}

	/** invokes the command */
	void invoke() {
		scope(exit) run = true;
		scope(failure) invoke_status = false;

		try
		{
			immutable auto result = execute([name] ~ args);
			invoke_status = result.status == 0;
			output = result.output;
		} catch (ProcessException e)
		{
			output = "command not found: " ~ name ~ "\n";
		}
	}

	/// invokes the command and result is success
	unittest {
		auto cmd = new Command("echo", ["12", "3"]);
		cmd.invoke();

		assert(cmd.success);
		immutable auto expectedOutput = "12 3\n";
		assert(cmd.output == expectedOutput, cmd.output ~ ` != ` ~ expectedOutput);

		cmd = new Command("true", []);
		cmd.invoke();

		assert(cmd.success);
		assert(cmd.output == "");
	}

	/// invokes the command and result is failure
	unittest {
		auto cmd = new Command("ls", ["i_am_100%_not_a_file_or_directory"]);
		cmd.invoke();

		assert(!cmd.success);
		// just don't want to deal with platform specific output:
		immutable auto expectedOutput = execute(["ls", "i_am_100%_not_a_file_or_directory"]).output;
		assert(cmd.output == expectedOutput, cmd.output ~ ` != ` ~ expectedOutput);
	}

	/// invokes the not found command
	unittest {
		auto cmd = new Command("this_cmd_does_not_exists", ["12", "3"]);
		cmd.invoke();

		assert(!cmd.success);
		assert(cmd.output == "command not found: this_cmd_does_not_exists\n");
	}

	/** command invocation status
	 * Returns: true if the command was successfully invoked, false otherwise
	 * Throws: [Exception] if the command was not invoked yet
	*/
	bool success() {
		if (run) {
			return invoke_status;
		} else {
			throw new Exception(`command "` ~ name ~ `" not invoked yet`);
		}
	}

	private bool invoke_status = false;
	private bool run = false;
}
