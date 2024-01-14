### MacOS Build issues

issue:
```
ld: warning: pointer not aligned at address 0x10016509F ('anon' + 146 from ../../../.dub/cache/sdlite/1.2.0/build/library-debug-Euv1mnZz1Zk-3iGZsMSgFQ/libsdlite.a(parser_419_6ff.o))
ld: warning: pointer not aligned at address 0x1001650E5 ('anon' + 216 from ../../../.dub/cache/sdlite/1.2.0/build/library-debug-Euv1mnZz1Zk-3iGZsMSgFQ/libsdlite.a(parser_419_6ff.o))
ld: unaligned pointer(s) for architecture x86_64
```
fix: 
in dub.settings.json:
```json
{
    "defaultBuildEnvironments": {
        "MACOSX_DEPLOYMENT_TARGET": "11"
    }
}
```

issue:
dub lint doesnt work (fails on running scanner)
open dscanner (dub list dscanner) dub.json and add
```json
"lflags-osx": ["-ld_classic"],
```
and modify:
```diff
- "\"$DC\" -run \"$PACKAGE_DIR/dubhash.d\""
+ "\"$DC\" -L-ld_classic -run \"$PACKAGE_DIR/dubhash.d\""
```
