import std.array;
import std.path: expandTilde, absolutePath, asNormalizedPath;
import std.file: exists, isDir, isSymlink;

/** represent path in a file system */
struct Path
{
	/** original (may be relative) path */
	string orig;
	/** abosulute path of the `orig` */
	string absolute;

	/** creates Path
	* Params:
	* 		path = `orig`
	*/
	this(string path)
	{
		orig = path;
		absolute = orig.expandTilde.absolutePath().asNormalizedPath().array;
	}

	/** Returns: true if Path exists in a file system */
	bool exists()
	{
		return absolute.exists;
	}

	/** Returns: true if Path is a directory in a file system */
	bool isDir()
	{
		return absolute.isDir;
	}

	/** Returns: true if Path is a symbolic link in a file system */
	bool isSymlink()
	{
		return absolute.isSymlink;
	}
}
