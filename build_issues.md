## MacOS build issues

#### unaligned pointer(s)

issue:

linking errors like this:

```
ld: warning: pointer not aligned at address 0x10016509F ('anon' + 146 from ../../../.dub/cache/sdlite/1.2.0/build/library-debug-Euv1mnZz1Zk-3iGZsMSgFQ/libsdlite.a(parser_419_6ff.o))
ld: warning: pointer not aligned at address 0x1001650E5 ('anon' + 216 from ../../../.dub/cache/sdlite/1.2.0/build/library-debug-Euv1mnZz1Zk-3iGZsMSgFQ/libsdlite.a(parser_419_6ff.o))
ld: unaligned pointer(s) for architecture x86_64
```

fix:

set `MACOSX_DEPLOYMENT_TARGET` environment variable to `11` (or `12`):
```bash
env MACOSX_DEPLOYMENT_TARGET=11 dub
```

#### symbol count from symbol table and dynamic symbol table differ

issue:

linking, when XCode version is
[15](https://developer.apple.com/documentation/xcode-release-notes/xcode-15-release-notes#Known-Issues), errors like this:

```
ld: multiple errors: symbol count from symbol table and dynamic symbol table differ in '/Users/kucaahbe/.dub/cache/myrc/0.2.1/build/application-debug-adg7nRO7nk0vUCCcUFqMMw/myrc.o' in '/Users/kucaahbe/.dub/cache/myrc/0.2.1/build/application-debug-adg7nRO7nk0vUCCcUFqMMw/myrc.o'; address=0x0 points to section(2) with no content in '/Library/D/dmd/lib/libphobos2.a[3233](config_a98_4c3.o)'
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

fix:

add `-L-ld_classic` to dmd flags, either:

```bash
env DFLAGS="-L-ld_classic" dub
```

or issue could be solved globally for dmd, by copying [`dmd.conf`](https://dlang.org/dmd-osx.html#dmd-conf) file to
any [allowed location](https://dlang.org/dmd-osx.html#dmd-conf) and appending `-L-ld_classic` there:

```ini
; ~/.dmd.conf
[Environment]

; on OSX (when dmd isntalled from .dmg) the original config file is located at
; /Library/D/dmd/bin/dmd.conf and its content should be used as base.
; Original content:
;DFLAGS=-I/Library/D/dmd/src/phobos -I/Library/D/dmd/src/druntime/import -L-L/Library/D/dmd/lib
DFLAGS=-I/Library/D/dmd/src/phobos -I/Library/D/dmd/src/druntime/import -L-L/Library/D/dmd/lib -L-ld_classic
```
