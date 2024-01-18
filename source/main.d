import core.stdc.stdlib;
import std.array;
import std.path: asNormalizedPath, baseName;
import cli;
import config_parser;
import path;
import config;

private Config app_config;

int main(string[] args)
{
	progname = args[0].asNormalizedPath.array.baseName();
	const auto configFile = Path("install.sdl");

	parse_config(configFile, app_config);

	if (args.length >= 2) {
		switch (args[1]) {
			case "install":
				cli_install(app_config);
				break;
			default:
				cli_status(args, app_config);
				break;
		}
	} else {
		cli_status(args, app_config);
	}

	return EXIT_SUCCESS;
}
