import symlink;
import command;

/** application configuration:
 * * holds symlinks info
 */
struct Config {
	//string[string] variables;
	/** symlinks declared in config file */
	Symlink[] symlinks;

	/** commands declared in config file */
	Command[] commands;
}
