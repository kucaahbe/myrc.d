import std.array;
import std.path: expandTilde, absolutePath, asNormalizedPath, dirName;
import std.file: exists, isDir, isSymlink;

/** represent path in a file system */
struct Path
{
	/** original (may be relative) path */
	string orig;
	/** an _absolute path of the [orig] */
	string absolute;

	/** creates [Path]
	* Params:
	* 		path = [orig]
	*/
	this(string path)
	{
		orig = path;
		absolute = orig.expandTilde.absolutePath().asNormalizedPath().array;
	}

	/// _path processing
	unittest
	{
		import std.file;
		import std.process;

		environment["HOME"] = "/my/home";
		immutable auto cwd = getcwd();
		immutable auto pathAbsolute = cwd ~ '/' ~ "file";

		// expands tilde
		auto path = Path("~/file");
		assert(path.absolute == "/my/home/file", path.absolute ~ "!=" ~ "/my/home/file");

		// absolute path
		path = Path("file");
		assert(path.absolute == pathAbsolute, path.absolute ~ "!=" ~ pathAbsolute);

		// normalise path
		path = Path("./file");
		assert(path.absolute == pathAbsolute, path.absolute ~ "!=" ~ pathAbsolute);
	}

	/** Returns: true if [Path] _exists in a file system */
	bool exists() inout
	{
		return absolute.exists;
	}

	/// returns true if [absolute] _exists
	unittest
	{
		import std.file;
		import std.process;
		import test_file;
		import test_dir;

		auto testDir = setupTestDir(__FILE__, __LINE__);
		scope(exit) removeTestDir(testDir);

		immutable auto file_path = testDir ~ "/app/source";

		const auto path = Path(file_path);
		assert(!path.exists);

		TestFile(file_path, "content").create;

		assert(path.exists);
	}

	/** Returns: [Path] representing _parent folder
	 */
	Path parent() inout
	{
		return Path(absolute.dirName);
	}

	/// returns parent folder as [Path]
	unittest
	{
		import std.file;

		immutable auto cwd = getcwd();

		immutable auto path = Path(".test/app/source");
		assert(path.parent.absolute == cwd ~ '/' ~ ".test/app");
	}

	/** Returns: true if [Path] is a directory in a file system */
	bool isDir() inout
	{
		return exists && absolute.isDir;
	}

	/// returns true if [absolute] exists and is a directory
	unittest
	{
		import std.file;
		import std.process;
		import test_file;
		import test_dir;

		auto testDir = setupTestDir(__FILE__, __LINE__);
		scope(exit) removeTestDir(testDir);

		immutable auto dir_path = testDir ~ "/app";

		const auto path = Path(dir_path);
		assert(!path.isDir);

		dir_path.mkdirRecurse;

		assert(path.isDir);
	}

	/** Returns: true if [Path] is a symbolic link in a file system */
	bool isSymlink() inout
	{
		return exists && absolute.isSymlink;
	}

	/// returns true if [absolute] exists and is a symbolic link
	unittest
	{
		import std.file;
		import std.process;
		import test_file;
		import test_dir;

		auto testDir = setupTestDir(__FILE__, __LINE__);
		scope(exit) removeTestDir(testDir);

		immutable auto dir_path = testDir ~ "/app";

		const auto path = Path(dir_path);
		assert(!path.isSymlink);

		dir_path.mkdirRecurse;
		assert(!path.isSymlink);

		TestFile(dir_path~'/'~"file", "content");
		assert(!path.isSymlink);

		remove(path.absolute);
		symlink("other_file_actually_doesnt_exist_but_who_cares", path.absolute);

		assert(path.isSymlink);
	}
}
