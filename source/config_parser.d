import sdlite.parser;
import sdlite.ast: SDLNode, SDLValue;
import std.file: exists, readText, FileException;
import std.utf: UTFException;
import std.conv: to;
import std.algorithm.searching: all;
import std.algorithm.iteration: map;
import std.array: join;
import symlink;
import path;
import config;

private immutable INSTALL_DIRECTIVE = "install";
private immutable LN_DIRECTIVE = "ln";

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

	if (".test".exists) ".test".rmdirRecurse;
	scope(exit) if (".test".exists) ".test".rmdirRecurse;

	auto config = Config();
	auto configFilePath = ".test/app/install.sdl";
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

/// _config file successfully parsed
unittest
{
	import std.file;
	import test_file;

	if (".test".exists) ".test".rmdirRecurse;
	scope(exit) if (".test".exists) ".test".rmdirRecurse;

	immutable auto cwd = getcwd();
	auto config = Config();
	auto configFilePath = ".test/app/install.sdl";
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

/// _config file warnings
unittest
{
	import std.file;
	import test_file;

	if (".test".exists) ".test".rmdirRecurse;
	scope(exit) if (".test".exists) ".test".rmdirRecurse;

	auto config = Config();
	auto configFilePath = ".test/app/install.sdl";
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

	if (".test".exists) ".test".rmdirRecurse;
	scope(exit) if (".test".exists) ".test".rmdirRecurse;

	auto config = Config();
	auto path = Path(".test/app/install.sdl");
	ubyte[] not_utf_data = [207, 250, 237];
	TestFile(path.absolute, not_utf_data).create;

	immutable auto exceptionMsg = collectExceptionMsg!ConfigFileException(parse_config(path, config));

	assert(matchFirst(exceptionMsg, "failed to read config file"),
			`"` ~ exceptionMsg ~ `" doesn't match ~/failed to read config file/`);
}

private void processSDLNode(ref SDLNode node, ref Config config, ref string[] warnings)
{
	if (node.qualifiedName == INSTALL_DIRECTIVE) {
		foreach (child_node ; node.children) {
			switch (child_node.qualifiedName) {
				case LN_DIRECTIVE:
					auto values = child_node.values;
					if (values.length == 2 && values.all!"a.isText") {
						config.symlinks ~= [Symlink(
								values[0].textValue,
								values[1].textValue
								)];
					} else {
						auto lnValues = values.map!((a) { return `"`~a.textValue~`"`; });
						warnings ~= [
							`ignoring incorrect directive: ` ~
								LN_DIRECTIVE ~ " " ~
								lnValues.join(" ") ~
								` (must have 2 text values)`
						];
					}
					break;
				default:
					warnings ~= [
						`ignoring unknown "` ~
							child_node.qualifiedName ~
							`" directive`
					];
					break;
			}
		}
	}
}
