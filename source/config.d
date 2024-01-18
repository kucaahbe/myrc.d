import symlink;

/** application configuration:
 * * holds symlinks info
 */
struct Config {
	//string[string] variables;
	/** symlinks declared in config file */
	Symlink[] symlinks;
}
