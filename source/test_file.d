version(unittest)
{
	import std.path;
	import std_file = std.file;
	import path;

	struct TestFile
	{
		Path path;

		this(string src)
		{
			path = Path(src);
		}

		this(string src, string content)
		{
			this(src);
			test_content = content;
		}

		ref TestFile create()
		{
			immutable auto dir = path.absolute.dirName;

			if (!std_file.exists(dir)) std_file.mkdirRecurse(dir);

			if (test_content.length > 0) {
				std_file.write(path.absolute, test_content);
			}

			return this;
		}

		private string test_content;
	}
}
