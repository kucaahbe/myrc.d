# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2024-01-31

### Fixed

- status output: when destination is regular file
- status output: when destination is symlink to non-existent file

## [0.2.0] - 2024-01-30

### Added

- better error messages for `myrc install`

### Fixed

- backup file name (now contains timestamp to avoid clashes and increases
  probability of backup success)

## [0.1.0] - 2024-01-24

### Added

- basic CLI commands: status (`myrc`), install (`myrc install`)
- experimental CLI output
- symlinking functionality
- selected [SDL](https://sdlang.org/) format for install file (`install.sdl`)

[unreleased]: https://github.com/kucaahbe/myrc.d/compare/v0.2.1...HEAD
[0.1.0]: https://github.com/kucaahbe/myrc.d/releases/tag/v0.1.0
[0.2.0]: https://github.com/kucaahbe/myrc.d/releases/tag/v0.2.0
[0.2.1]: https://github.com/kucaahbe/myrc.d/releases/tag/v0.2.1
