import sdlite.parser;
import sdlite.ast: SDLNode, SDLValue;
import std.file: exists, readText, FileException;
import std.utf: UTFException;
import std.conv: to;
import std.algorithm.searching: all;
import cli;
import symlink;
import path;
import config;

private immutable INSTALL_DIRECTIVE = "install";
private immutable LN_DIRECTIVE = "ln";

/** parses [SDL](https://sdlang.org/) config and sets up config
 * Params:
 *		config_file = Path to config file (install.sdl)
 *		config = app configuration instance
 */
void parse_config(Path config_file, ref Config config)
{
	if (!config_file.exists()) {
		cli_error("config file " ~ config_file.absolute ~ " does not exist");
		cli_fail();
	}

	immutable auto processNode = (ref SDLNode node) { processSDLNode(node,config); };

	try
	{
		parseSDLDocument!processNode(config_file.absolute.readText(), config_file.absolute);
	}
	catch (FileException e)
	{
		cli_error("failed to open config file:\n  " ~ e.msg);
		cli_fail();
	}
	catch (UTFException e)
	{
		cli_error("failed to read config file:\n  " ~ e.msg);
		cli_fail();
	}
	catch (SDLParserException e)
	{
		cli_error(
				"failed to parse config file at "
				~ config_file.absolute
				~ ":" ~ to!string(e.location.line+1) ~ ":" ~ to!string(e.location.column+1)
				~ ":\n  "
				~ e.error
				);
		cli_fail();
	}
}

private void processSDLNode(ref SDLNode node, ref Config config)
{
	if (node.qualifiedName == INSTALL_DIRECTIVE) {
		foreach (child_node ; node.children) {
			switch (child_node.qualifiedName) {
				case LN_DIRECTIVE:
					auto values = child_node.values;
					if (values.length == 2 && values.all!"a.isText") {
						config.symlinks ~= [Symlink(
								Path(values[0].textValue),
								Path(values[1].textValue)
								)];
					} else {
						// TODO: replace TODO with ln content: "ln "val1""
						cli_warning("ignoring incorrect \"" ~ LN_DIRECTIVE ~ "\" directive at TODO (must have 2 text values)");
					}
					break;
				default:
					cli_warning("ignoring unknown \"" ~ child_node.qualifiedName ~ "\" directive");
					break;
			}
		}
	}
}
