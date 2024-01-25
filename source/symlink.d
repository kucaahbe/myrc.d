import std.file: readLink, isSymlink, symlink, rename, exists, FileException;
import std.path: absolutePath, dirName, asNormalizedPath;
import std.functional: memoize;
import std.array;
import path;

/** symbolic link */
struct Symlink {
	/** _source file [Path] */
	Path source;
	/** _destination file [Path] */
	Path destination;

	/** creates new [Symlink]
	 * Params:
	 * 	src = source path (may be relative to current working directory)
	 * 	dest = destination path
	 */
	this(string src, string dest)
	{
		source = Path(src);
		destination = Path(dest);
	}

	/// initialisation could be done with strings
	unittest
	{
		import std.file;

		immutable auto srcPath = ".test/app/source";
		immutable auto destPath = ".test/home/destination";
		immutable auto cwd = getcwd();

		const auto link = Symlink(srcPath, destPath);

		immutable auto sourcePathAbsolute = cwd ~ '/' ~ srcPath;
		immutable auto destinationPathAbsolute = cwd ~ '/' ~ destPath;

		assert(link.source.absolute == sourcePathAbsolute,
				link.source.absolute ~ "!=" ~ sourcePathAbsolute);
		assert(link.destination.absolute == destinationPathAbsolute,
				link.destination.absolute ~ "!=" ~ destinationPathAbsolute);
	}

	/** test symlink correctness
	 * Returns: source == destination
	 */
	bool ok()
	{
		return source.absolute == destinationActual;
	}

	/// returns true if symlink exists and false otherwise
	unittest
	{
		import std.file;
		import test_file;

		if (".test".exists) ".test".rmdirRecurse;
		scope(exit) if (".test".exists) ".test".rmdirRecurse;

		auto srcPath = ".test/app/source";
		auto destPath = ".test/home/destination";
		TestFile(srcPath, "content").create;
		TestFile(destPath).create;

		auto link = Symlink(srcPath, destPath);

		assert(!link.ok);
		link.link();
		assert(link.ok);
	}

	/** creates symbolic _link in the file system
	 * (creates backup of the destination if it exists)
	 * Returns: path of the backup file if backup was created
	 * Bugs: the name of the backup file is currently incorrect (must be
	 * `filename.TIMESTAMP.bak`)
	 */
	string link()
	{
		if (!source.exists)
			throw new FileException(source.absolute, "file or directory does not exist");

		auto parentDir = destination.parent;

		if (!parentDir.exists)
			throw new FileException(parentDir.absolute, "directory does not exist");

		if (!parentDir.isDir)
			throw new FileException(parentDir.absolute, "not a directory");

		string backupPath;

		if (destination.exists)
			backupPath = backup();

		symlink(source.absolute, destination.absolute);

		return backupPath;
	}

	/// **success case 1**: creates symlink when destination doesn't exist
	unittest
	{
		import std.file;
		import std.path;
		import test_file;

		if (".test".exists) ".test".rmdirRecurse;
		scope(exit) if (".test".exists) ".test".rmdirRecurse;

		auto srcPath = ".test/app/source";
		auto destPath = ".test/home/destination";

		TestFile(srcPath, "content").create;
		TestFile(destPath).create;

		auto link = Symlink(srcPath, destPath);
		link.link();

		assert(link.destination.absolute.isSymlink);
		assert(link.destination.absolute.readLink == link.source.absolute);
	}

	/** **success case 2**: creates symlink when destination exists (creating backup
	 * and returning it's path)
	 */
	unittest
	{
		import std.file;
		import std.path;
		import test_file;

		if (".test".exists) ".test".rmdirRecurse;
		scope(exit) if (".test".exists) ".test".rmdirRecurse;

		auto srcPath = ".test/app/source";
		auto destPath = ".test/home/destination";
		immutable auto cwd = getcwd();

		TestFile(srcPath, "src content").create;
		TestFile(destPath, "dest content").create;

		auto link = Symlink(srcPath, destPath);
		immutable auto backup = link.link();

		immutable auto destPathBackup = cwd ~ '/' ~ destPath ~ ".bak";

		assert(link.destination.absolute.isSymlink);
		assert(link.destination.absolute.readLink == link.source.absolute);
		assert(backup == destPathBackup, backup ~ "!=" ~ destPathBackup);
	}

	/** **fail case**: destination does not exist
		* (raises [FileException] with corresponding message)
		*/
	unittest
	{
		import std.file;
		import std.path;
		import test_file;
		import std.exception: collectExceptionMsg;

		if (".test".exists) ".test".rmdirRecurse;
		scope(exit) if (".test".exists) ".test".rmdirRecurse;

		immutable auto cwd = getcwd();
		auto srcPath = ".test/app/source";
		auto destPath = ".test/home/destination";

		TestFile(srcPath, "content").create;
		// only create .test/
		TestFile(destPath.dirName).create;
		assert(destPath.dirName.dirName.isDir);

		auto link = Symlink(srcPath, destPath);

		immutable auto exceptionMsg = collectExceptionMsg!FileException(link.link);
		immutable auto expectedExceptionMsg = cwd ~ "/.test/home" ~ ": directory does not exist";

		assert(exceptionMsg == expectedExceptionMsg, exceptionMsg ~ " != " ~ expectedExceptionMsg);
	}

	/** **fail case**: destination is not a directory
	 * (raises [FileException] with corresponding message)
	 */
	unittest
	{
		import std.file;
		import std.path;
		import test_file;
		import std.exception: collectExceptionMsg;

		if (".test".exists) ".test".rmdirRecurse;
		scope(exit) if (".test".exists) ".test".rmdirRecurse;

		auto srcPath = ".test/app/source";
		auto destPath = ".test/home/destination";
		immutable auto cwd = getcwd();

		TestFile(srcPath, "src content").create;
		// destination directory is a file
		TestFile(destPath.dirName, "dest content").create;

		auto link = Symlink(srcPath, destPath);

		immutable auto exceptionMsg = collectExceptionMsg!FileException(link.link);
		immutable auto expectedExceptionMsg = cwd ~ '/' ~ destPath.dirName ~ ": not a directory";

		assert(exceptionMsg == expectedExceptionMsg, exceptionMsg ~ " != " ~ expectedExceptionMsg);
	}

	/** **fail case**: source does not exist
	 * (raises [FileException] with corresponding message)
	 */
	unittest
	{
		import std.file;
		import std.path;
		import test_file;
		import std.exception: collectExceptionMsg;

		if (".test".exists) ".test".rmdirRecurse;
		scope(exit) if (".test".exists) ".test".rmdirRecurse;

		auto srcPath = ".test/app/source";
		auto destPath = ".test/home/destination";
		immutable auto cwd = getcwd();

		TestFile(destPath).create;
		assert(destPath.dirName.isDir);

		auto link = Symlink(srcPath, destPath);

		immutable auto exceptionMsg = collectExceptionMsg!FileException(link.link);
		immutable auto expectedExceptionMsg = cwd ~ "/.test/app/source" ~ ": file or directory does not exist";

		assert(exceptionMsg == expectedExceptionMsg, exceptionMsg ~ " != " ~ expectedExceptionMsg);
	}

	/** Returns: _actual [Path] of the destination */
	Path actual() const
	{
		return Path(destinationActual);
	}

	/// actual path of the symbolic link destination
	// TODO: cases to test:
	// * destination doesn't exists
	// * destination is not a symlink - this is what's done
	// * destination is a symlink
	unittest
	{
		import std.file;
		import std.path;
		import test_file;

		if (".test".exists) ".test".rmdirRecurse;
		scope(exit) if (".test".exists) ".test".rmdirRecurse;

		auto srcPath = ".test/app/source";
		auto destPath = ".test/home/destination";
		immutable auto cwd = getcwd();

		TestFile(srcPath, "src content").create;
		TestFile(destPath, "dest content").create;

		const auto link = Symlink(srcPath, destPath);
		immutable auto actualPathAbsolute = cwd ~ '/' ~ destPath;

		assert(link.actual.absolute == actualPathAbsolute);
	}

	private string destinationActual() const
	{
		if (!destination.absolute.exists) {
			return [];
		} else if (destination.absolute.isSymlink) {
			return readLink(destination.absolute).absolutePath(destination.absolute.dirName).asNormalizedPath.array;
		} else {
			return destination.absolute;
		}
	}

	private string backup()
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
}
