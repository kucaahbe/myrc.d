import std.file: readLink, isSymlink, symlink, rename, exists, FileException;
import std.path: absolutePath, dirName, asNormalizedPath;
import std.functional: memoize;
import std.array;
import path;

/** symbolic link */
struct Symlink {
	/** source path */
	Path source;
	/** destination path */
	Path destination;

	/** test symlink correctness
	 * Returns: source == destination
	 */
	bool ok()
	{
		return source.absolute == destinationActual;
	}

	/** creates symbolic link in the file system */
	void link()
	{
		symlink(source.absolute, destination.absolute);
	}

	/** creates backup of the destination
	 * Returns: pach of the backup file if backup was created
   * Bugs: the name of the backup file is currently incorrect (must be
	 * `filename.TIMESTAMP.bak`)
	 */
	string backup()
	{
		auto backup = destination.absolute ~ ".bak";
		try
		{
			rename(destination.absolute, backup);
		} catch (FileException e)
		{
			import std.stdio: writeln;
			writeln("DEBUG:", destination.absolute, " ", backup);
			writeln(e.message, " ", e.errno);
			backup = "FAILED BACKUP";
		}
		return backup;
	}

	/** Returns: actual `Path` of the desctination */
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
