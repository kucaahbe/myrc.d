import std.array: join;
import std.process;
import path;

/** represents a shell command */
class Command {
	/** command _name */
	string name;
	/** command arguments */
	string[] args;
	/** command _output */
	string output;
	/** file system artifacts command expected to create */
	CommandOutcome[] outcomes;

	/** creates a new command with the given _name and arguments
	 * Params:
	 * 		name = command name (e.g. "ls")
	 * 		args = command arguments (e.g. ["-l", "-a"])
	 */
	this(string name, string[] args) {
		this.name = name;
		this.args = args;
	}

	/** returns string representation of the command
		(command name and arguments) */
	string inspect() {
		return name ~ ' ' ~ args.join(' ');
	}

	/// string representation of [Command]
	unittest {
		auto cmd = new Command("echo", ["12", "3"]);
		assert(cmd.inspect == "echo 12 3");
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

/** represents a file system artifact, created by Command */
class CommandOutcome
{
	/** type of the outcome */
	enum
	{
		/** file */
		File,
		/** directory */
		Directory,
		/** symbolic link */
		Symlink
	}

	/** type of the artifact */
	int type;
	/** Path to the artifact */
	Path path;

	/** creates a new outcome with the given type and path
	 * Params:
	 * 		type = type of the artifact
	 * 		path = path to the artifact
	 */
	this(int type, Path path)
	{
		this.type = type;
		this.path = path;
	}

	/** test if outcome criteria is satisfied
		* Returns: true if the outcome exists */
	bool ok() {
		switch (type) {
			case File:
				return path.isFile;
			case Directory:
				return path.isDir;
			case Symlink:
				return path.isSymlink;
			default:
				return false;
		}
	}

	/// returns true if the outcome exists
	unittest {
		import std.file;
		import std.process;
		import std.conv;
		import test_file;
		import test_dir;

		auto testDir = setupTestDir(__FILE__, __LINE__);
		scope(exit) removeTestDir(testDir);

		auto file = testDir ~ "/file";
		auto dir = testDir ~ "/dir";
		auto symlink = testDir ~ "/symlink";

		auto path = Path(file);
		auto outcome = new CommandOutcome(CommandOutcome.File, path);
		assert(!outcome.ok);
		TestFile(file, "content").create();
		assert(outcome.ok);

		path = Path(dir);
		outcome = new CommandOutcome(CommandOutcome.Directory, path);
		assert(!outcome.ok);
		dir.mkdir;
		assert(outcome.ok);

		path = Path(symlink);
		outcome = new CommandOutcome(CommandOutcome.Symlink, path);
		assert(!outcome.ok);
		file.symlink(symlink);
		assert(outcome.ok);
	}
}
