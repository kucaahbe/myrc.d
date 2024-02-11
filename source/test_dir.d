version(unittest)
{
	import std.file;
	import std.path;
	import std.string;
	import std.conv;

	string setupTestDir(string filename, uint line)
	{
		auto dir = ".test_" ~ filename.replace('/', '_') ~ "_" ~ to!string(line);

		if (dir.exists) dir.rmdirRecurse;

		return dir;
	}

	void removeTestDir(string dir)
	{
		if (dir.exists) dir.rmdirRecurse;
	}
}
