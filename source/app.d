import std.stdio;
import std.array;
import std.conv: to;

private immutable auto CONFIG_FILENAME = "install.sdl";
private string progname = "myconfigs";
int status_variant = 1;

int main(string[] args)
{
	import std.path: absolutePath, asNormalizedPath, baseName;
	import std.file: exists, readText, FileException;
	import std.utf: UTFException;

	progname = args[0].asNormalizedPath.array.baseName();
	const auto configFilePath = CONFIG_FILENAME.absolutePath();

	if (!configFilePath.exists()) {
		print_error("config file " ~ configFilePath ~ " does not exist");
		return 1;
	}

	import sdlite.parser;
	try
	{
		parseSDLDocument!(processSDLNode)(configFilePath.readText(), configFilePath);
	}
	catch (FileException e)
	{
		print_error("failed to open config file:\n  " ~ e.msg);
		return 1;
	}
	catch (UTFException e)
	{
		print_error("failed to read config file:\n  " ~ e.msg);
		return 1;
	}
	catch (SDLParserException e)
	{
		print_error(
				"failed to parse config file at "
				~ configFilePath
				~ ":" ~ to!string(e.location.line+1) ~ ":" ~ to!string(e.location.column+1)
				~ ":\n  "
				~ e.error
				);
		return 1;
	}

	if (args.length >= 2) {
		switch (args[1]) {
			case "install":
				makeInstall();
				break;
			default:
				showStatus(args);
				break;
		}
	} else {
		showStatus(args);
	}

	return 0;
}

void showStatus(ref string[] args)
{
	parseCliOptionsForStatus(args);
 
	switch (status_variant) {
		case 1:
			printStatus1();
			break;
		case 2:
			printStatus2();
			break;
		default:
			printStatus1();
	}
}

void parseCliOptionsForStatus(ref string[] args)
{
	import std.getopt;


	auto helpInformation = getopt(
			args,
			"l", "status variant", &status_variant,
			);

	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("Some information about the program.",
				helpInformation.options);
	}
}

private immutable INSTALL_DIRECTIVE = "install";
private immutable LN_DIRECTIVE = "ln";

private struct Path
{
	string orig;
	string absolute;

	this(string path)
	{
		import std.path: expandTilde, absolutePath, asNormalizedPath;
		orig = path;
		absolute = orig.expandTilde.absolutePath().asNormalizedPath().array;
	}

	bool exists()
	{
		import std.file: exists;
		return absolute.exists;
	}

	bool isDir()
	{
		import std.file: isDir;
		return absolute.isDir;
	}

	bool isSymlink()
	{
		import std.file: isSymlink;
		return absolute.isSymlink;
	}
}

private struct Symlink {
	Path source;
	Path destination;

	import std.file: readLink, isSymlink, symlink, rename, exists, FileException;
	import std.path: absolutePath, dirName, asNormalizedPath;
	import std.functional: memoize;

	bool ok()
	{
		return source.absolute == destinationActual;
	}

	void link()
	{
		symlink(source.absolute, destination.absolute);
	}

	string backup()
	{
		auto backup = destination.absolute ~ ".bak";
		try
		{
			rename(destination.absolute, backup);
		} catch (FileException e)
		{
			writeln("DEBUG:", destination.absolute, " ", backup);
			writeln(e.message, " ", e.errno);
			backup = "FAILED BACKUP";
		}
		return backup;
	}

	Path actual()
	{
		return Path(destinationActual);
	}

	private string destinationActual()
	{
		if (!destination.absolute.exists) {
			return [];
		} else if (destination.absolute.isSymlink) {
			return readLink(destination.absolute).absolutePath(destination.absolute.dirName).asNormalizedPath.array;
		} else {
			return destination.absolute;
		}
	}
}

private struct Config {
	//string[string] variables;
	Symlink[] symlinks;
}

private Config config;

import sdlite.ast: SDLNode, SDLValue;
private void processSDLNode(ref SDLNode node)
{
	if (node.qualifiedName == INSTALL_DIRECTIVE) {
		foreach (child_node ; node.children) {
			switch (child_node.qualifiedName) {
				case LN_DIRECTIVE:
					auto values = child_node.values;
					import std.algorithm.searching: all;
					if (values.length == 2 && values.all!"a.isText") {
						config.symlinks ~= [Symlink(
								Path(values[0].textValue),
								Path(values[1].textValue)
								)];
					} else {
						// TODO: replace TODO with ln content: "ln "val1""
						print_warning("ignoring incorrect \"" ~ LN_DIRECTIVE ~ "\" directive at TODO (must have 2 text values)");
					}
					break;
				default:
					print_warning("ignoring unknown \"" ~ child_node.qualifiedName ~ "\" directive");
					break;
			}
		}
	}
}

private void makeInstall()
{
	import std.file: getcwd;
	import std.format: format;
	import std.algorithm.iteration: map, filter;
	import std.algorithm.searching: maxElement;

	string output = getcwd ~ " install:\n";

	foreach (symlink ; config.symlinks) {

		if (!symlink.source.exists) {
			output ~= "# " ~ symlink.source.absolute ~ ": no such file or directory\n";
			continue;
		}

		output ~= " ";
		output ~= symlink.destination.absolute;

		if (symlink.ok) {
			output ~= " -> ";
			output ~= symlink.source.absolute;
		} else {
			string backup;
			if (symlink.destination.exists) {
				backup = symlink.backup();
				symlink.link();
			} else {
				symlink.link();
			}
			output ~= " -> ";
			output ~= symlink.source.absolute;
			if (backup)
				output ~= " (backup: " ~ backup ~ ")";
		}
		output ~= "\n";
	}

	write(output);
}

private void printStatus1()
{
	import std.file: getcwd;
	import std.format: format;
	import std.algorithm.iteration: map, filter;
	import std.algorithm.searching: maxElement;

	auto symlinksLengths = ((config.symlinks.filter!(s => s.source.exists))
			.map!(s => s.source.orig.length));
	auto max_src_length = to!string(symlinksLengths.empty ? 0 : symlinksLengths.maxElement);

	string output = getcwd ~ ":\n";

	foreach (symlink ; config.symlinks) {
		output ~= symlink.ok ? "+ " : "- ";
		output ~= symlink.destination.absolute;

		if (symlink.ok) {
			output ~= " -> ";
			output ~= symlink.source.absolute;
		} else {
			output ~= " # ";
			if (symlink.destination.exists) {
				if (symlink.destination.isDir) {
					output ~= "is a directory";
				} else if (symlink.destination.isSymlink) {
					output ~= "-> ";
					output ~= symlink.actual.absolute;
				}
			} else {
				output ~= "no such file or directory";
			}
			output ~= " (need -> ";
			output ~= symlink.source.absolute;
			if (!symlink.source.exists) {
				output ~= ": no such file or directory";
			}
			output ~= ")";
		}
		output ~= "\n";
	}

	write(output);
}

private void printStatus2()
{
	writeln("TODO: status 2");
}

private void print_error(const string msg)
{
	stderr.writeln(progname ~ ": " ~ msg);
}

private void print_warning(const string msg)
{
	stderr.writeln(progname ~ ": WARNING: " ~ msg);
}
