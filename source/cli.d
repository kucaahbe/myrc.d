import std.file: getcwd;
import std.format: format;
import std.algorithm.iteration: map, filter;
import std.algorithm.searching: maxElement;
import std.stdio;
import core.stdc.stdlib;
import std.conv: to;
import config;

/** program name (will be displayed in CLI messages) */
string progname = "myrc";

private int status_variant = 1;

/** status CLI output
 * Params:
 *		args = CLI args
 *		app_config = application config
 */
void cli_status(ref string[] args, ref Config app_config)
{
	parseCliOptionsForStatus(args);

	switch (status_variant) {
		case 1:
			printStatus1(app_config);
			break;
		case 2:
			printStatus2();
			break;
		default:
			printStatus1(app_config);
	}
}

/** performs install action and displays status to standard output stream */
void cli_install(ref Config app_config)
{
	string output = getcwd ~ " install:\n";

	foreach (symlink ; app_config.symlinks) {
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
			string backup = symlink.link();
			output ~= " -> ";
			output ~= symlink.source.absolute;
			if (backup)
				output ~= " (backup: " ~ backup ~ ")";
		}
		output ~= "\n";
	}

	write(output);
}

/** display CLI error on standard error stream */
void cli_error(const string msg)
{
	stderr.writeln(progname ~ ": " ~ msg);
}

/** display CLI warning on standard error stream */
void cli_warning(const string msg)
{
	stderr.writeln(progname ~ ": WARNING: " ~ msg);
}

/** exit with failure status */
void cli_fail() @noreturn
{
	exit(EXIT_FAILURE);
}

private void parseCliOptionsForStatus(ref string[] args)
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

private void printStatus1(ref Config app_config)
{
	import std.file: getcwd;
	import std.format: format;
	import std.algorithm.iteration: map, filter;
	import std.algorithm.searching: maxElement;

	//auto symlinksLengths = ((app_config.symlinks.filter!(s => s.source.exists))
	//		.map!(s => s.source.orig.length));
	//immutable auto max_src_length = to!string(symlinksLengths.empty ? 0 : symlinksLengths.maxElement);

	string output = getcwd ~ ":\n";

	foreach (symlink ; app_config.symlinks) {
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
