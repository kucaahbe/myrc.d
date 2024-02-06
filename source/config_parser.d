import sdlite.parser;
import sdlite.ast: SDLNode, SDLValue;
import std.file: exists, readText, FileException;
import std.utf: UTFException;
import std.conv: to;
import std.algorithm.searching: all;
import std.algorithm.iteration: map;
import std.array: join, split;
import symlink;
import path;
import config;
import command;

/// config file directives
enum Directive : string
{
    Install = "install",
    Ln = "ln",
    Exec = "exec",
}

/** thrown when config file:
 * * not found
 * * can not be opened
 * * parse error occured
 */
class ConfigFileException : Exception
{
	/** Params:
	 *		msg = message to display to the user
	 *		file = source file
	 *		line = line
	 */
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

/** parses [SDL](https://sdlang.org/) config_file and sets up config
 * Params:
 *		config_file = [Path] to config file (install.sdl)
 *		config = app configuration instance
 */
string[] parse_config(Path config_file, ref Config config)
{
	if (!config_file.exists()) {
		throw new ConfigFileException("config file " ~ config_file.absolute ~ " does not exist");
	}

	string[] warnings;
	immutable auto processNode = (ref SDLNode node) { processSDLNode(node,config,warnings); };

	try
	{
		parseSDLDocument!processNode(config_file.absolute.readText(), config_file.absolute);
	}
	catch (FileException e)
	{
		throw new ConfigFileException("failed to open config file:\n  " ~ e.msg);
	}
	catch (UTFException e)
	{
		throw new ConfigFileException("failed to read config file:\n  " ~ e.msg);
	}
	catch (SDLParserException e)
	{
		throw new ConfigFileException(
				"failed to parse config file at "
				~ config_file.absolute
				~ ":" ~ to!string(e.location.line+1) ~ ":" ~ to!string(e.location.column+1)
				~ ":\n  "
				~ e.error
				);
	}

	return warnings;
}

/// _config file not found
unittest
{
	import std.exception;
	import std.regex;

	auto config = Config();
	auto path = Path("not_found");

	auto exceptionMsg = collectExceptionMsg!ConfigFileException(parse_config(path, config));

	assert(matchFirst(exceptionMsg, "does not exist"),
			`"` ~ exceptionMsg ~ `" doesn't match ~/does not exist/`);
}

/// _config file parse error
unittest
{
	import std.file;
	import std.exception;
	import std.regex;
	import test_file;
	import test_dir;

	auto testDir = setupTestDir(__FILE__, __LINE__);
	scope(exit) removeTestDir(testDir);

	auto config = Config();
	auto configFilePath = testDir ~ "/app/install.sdl";
	auto configFileContent = q"CFG
install {
# parse error here:
	ln `a` b`
}
CFG";
	TestFile(configFilePath, configFileContent).create;

	auto exceptionMsg = collectExceptionMsg!ConfigFileException(parse_config(Path(configFilePath), config));

	assert(matchFirst(exceptionMsg, "failed to parse config file at"),
			`"` ~ exceptionMsg ~ `" doesn't match /failed to parse config file at/`);
}

/// **_config file parsed**: ln directive
unittest
{
	import std.file;
	import test_file;
	import test_dir;

	auto testDir = setupTestDir(__FILE__, __LINE__);
	scope(exit) removeTestDir(testDir);

	immutable auto cwd = getcwd();
	auto config = Config();
	auto configFilePath = testDir ~ "/app/install.sdl";
	auto configFileContent = q"CFG
install {
	ln `a` `b`
}
CFG";
	TestFile(configFilePath, configFileContent).create;

	parse_config(Path(configFilePath), config);
	assert(config.symlinks.length == 1);
	assert(config.symlinks[0].source.absolute == cwd~"/a");
	assert(config.symlinks[0].destination.absolute == cwd~"/b");
}

/// **_config file parsed**: exec directive
unittest
{
	import std.file;
	import test_file;
	import test_dir;

	auto testDir = setupTestDir(__FILE__, __LINE__);
	scope(exit) removeTestDir(testDir);

	auto config = Config();
	auto configFilePath = testDir ~ "/app/install.sdl";
	auto configFileContent = q"CFG
install {
  exec `cmd "space  separated"    arguments` {
    # cwd `~/some/dir` # machine idea

    creates:file `~/some/dir/file`
  }
}
CFG";
	TestFile(configFilePath, configFileContent).create;

	parse_config(Path(configFilePath), config);

	assert(config.commands.length == 1);
	const auto command = config.commands[0];
	assert(command.name == "cmd");
	assert(command.args == [`space  separated`, "arguments"]);

	assert(command.outcomes.length == 1, `command.outcomes length is incorrect: `~command.outcomes.to!string);
	assert(command.outcomes[0].type == CommandOutcome.File,
			`command.outcomes[0].type is incorrect: `~command.outcomes[0].type.to!string);
	assert(command.outcomes[0].path.absolute == Path("~/some/dir/file").absolute,
			`command.outcomes[0].path is incorrect: `~command.outcomes[0].path.to!string);
}

/// _config file warnings
unittest
{
	import std.file;
	import test_file;
	import test_dir;

	auto testDir = setupTestDir(__FILE__, __LINE__);
	scope(exit) removeTestDir(testDir);

	auto config = Config();
	auto configFilePath = testDir ~ "/app/install.sdl";
	auto configFileContent = q"CFG
install {
	ln "too" "many" "params"
	bad_directive 1 2 3
	ln `a` `b`
}
CFG";
	TestFile(configFilePath, configFileContent).create;

	auto warnings = parse_config(Path(configFilePath), config);

	assert(warnings[0] == `ignoring incorrect directive: ln "too" "many" "params" (must have 2 text values)`,
			warnings[0] ~ " is incorrect");
	assert(warnings[1] == `ignoring unknown "bad_directive" directive`,
			warnings[1] ~ " is incorrect");
}

/// _config file can not be opened
unittest
{
	import std.exception;
	import std.regex;

	auto config = Config();
	auto path = Path("not_found");

	immutable auto exceptionMsg = collectExceptionMsg!ConfigFileException(parse_config(path, config));
	immutable auto expectedMsg = "config file " ~ path.absolute ~ " does not exist";

	assert(exceptionMsg == expectedMsg, exceptionMsg ~ ` != ` ~ expectedMsg);
}

/// _config file content is not valid UTF
unittest
{
	import std.file;
	import std.exception;
	import std.regex;
	import test_file;
	import test_dir;

	auto testDir = setupTestDir(__FILE__, __LINE__);
	scope(exit) removeTestDir(testDir);

	auto config = Config();
	auto path = Path(testDir ~ "/app/install.sdl");
	ubyte[] not_utf_data = [207, 250, 237];
	TestFile(path.absolute, not_utf_data).create;

	immutable auto exceptionMsg = collectExceptionMsg!ConfigFileException(parse_config(path, config));

	assert(matchFirst(exceptionMsg, "failed to read config file"),
			`"` ~ exceptionMsg ~ `" doesn't match ~/failed to read config file/`);
}

private void processSDLNode(ref SDLNode node, ref Config config, ref string[] warnings)
{
	if (node.qualifiedName != Directive.Install) return;

	foreach (child_node ; node.children) {
		switch (child_node.qualifiedName) {
			case Directive.Ln:
				processLn(child_node.values, config, warnings);
				break;
			case Directive.Exec:
				processExec(child_node, config, warnings);
				break;
			default:
				warnings ~= [
					`ignoring unknown "` ~ child_node.qualifiedName ~ `" directive`
				];
				break;
		}
	}
}

private void processLn(ref SDLValue[] values, ref Config config, ref string[] warnings)
{
	if (values.length == 2 && values.all!"a.isText") {
		config.symlinks ~= [Symlink(values[0].textValue, values[1].textValue)];
	} else {
		auto lnValues = values.map!((a) { return `"`~a.textValue~`"`; });

		warnings ~= [
			`ignoring incorrect directive: ` ~ Directive.Ln ~ " " ~
				lnValues.join(" ") ~ ` (must have 2 text values)`
		];
	}
}

private void processExec(ref SDLNode node, ref Config config, ref string[] warnings)
{
	if (node.values.length == 0 ||
			!node.values[0].isText ||
			node.values[0].textValue.length == 0) {
		warnings ~= [
			`ignoring incorrect directive: ` ~ Directive.Exec
				~ ` (specify a command to execute)`
		];
		return;
	}

	auto rawCommand = parseCmd(node.values[0].textValue);
	auto command = new Command(rawCommand[0], rawCommand[1..$]);

	foreach (cmdNode ; node.children) {
		switch (cmdNode.namespace) {
			case "creates":
				switch (cmdNode.name) {
					case "file":
						if (cmdNode.values.length == 1 && cmdNode.values[0].isText) {
							auto path = Path(cmdNode.values[0].textValue);
							command.outcomes ~= new CommandOutcome(CommandOutcome.File, path);
						} else {
							warnings ~= [
								`ignoring incorrect "`~cmdNode.qualifiedName~`" directive: ` ~ cmdNode.values.to!string
									~ ` (must have 1 text value)`
							];
						}
						break;
					default:
						warnings ~= [
							`ignoring unknown "` ~ cmdNode.qualifiedName ~ `" directive`
						];
						break;
				}
				break;
			default:
				warnings ~= [
					`ignoring unknown "` ~ cmdNode.qualifiedName ~ `" directive`
				];
				break;
		}
	}

	config.commands ~= [command];
}

private string[] parseCmd(string cmd)
{
	string[] command;
	size_t i = 0;

	//import std.stdio;

	auto consumeSpace = () { while (i < cmd.length && cmd[i] == ' ') i++; };
	auto consumeArgument = (char sep) {
		size_t start = i;
		while (i < cmd.length && cmd[i] != sep) {
			//writefln("cmd[%s] = %s", i, cmd[i]);
			i++;
		}

		if (i == cmd.length) {
			//if (cmd[i] == sep)
			//	throw new ConfigFileException("unterminated string: " ~ cmd);
			return cmd[start..$];
		} else {
			//writefln("argument i: %s, cmd[i]=%s `%s` (sep=%s)", i, cmd[i], cmd[start..i], sep);
			return cmd[start..i];
		}
	};

	while (i < cmd.length) {
		consumeSpace();
		switch (cmd[i]) {
			case '"':
				i++;
				command ~= consumeArgument('"');
				i++;
				break;
			case '\'':
				i++;
				command ~= consumeArgument('\'');
				i++;
				break;
			default:
				command ~= consumeArgument(' ');
				break;
		}
	}

	return command;
}
