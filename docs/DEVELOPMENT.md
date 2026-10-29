# Development

The `app` directory contains the files Quartus loads. Tcl starts Python jobs that run Slang and Verible in the background. A persistent Node worker tokenizes source code with the bundled TextMate grammar.

The native code connects these jobs to Quartus:

- `qol_native.c` registers the `qol_native` Tcl command and controls the editor's Scintilla and Qt widgets.
- `qol_options.inc` adds the settings to Tools → Options.
- `qol_pump.c` runs Tcl timers on the existing GUI thread.
- `qol_worker.c` starts tools in hidden windows with a separate DLL search path.
- `version-warning.c` displays the warning for untested Quartus builds.

Dark presets append a stylesheet through Qt's `QApplication::setStyleSheet`. The bridge saves the original stylesheet before the first change and restores it for light presets or when QOL stops. Tcl applies it once per theme change, not on every poll. Widget-specific styles and custom painting can override application rules. The bridge doesn't change Windows theme settings or fonts.

The Options controls manage Verible indentation and line length, Slang's `-Wextra` flag and hover delay. `settings.tcl` validates and saves these values, then updates only the corresponding arguments. Other formatter and compiler arguments remain in `user/config.tcl`.

## Build the helpers

On Windows x64, use MinGW-w64 GCC and `windres`:

```powershell
cd app
gcc -std=c11 -O2 -shared -static-libgcc -Wall -Wextra -o qolnative-v15.dll qol_native.c
gcc -std=c11 -O2 -shared -static-libgcc -Wall -Wextra -o qolpump.dll qol_pump.c
gcc -std=c11 -O2 -static-libgcc -municode -Wall -Wextra -o qolworker-v3.exe qol_worker.c
windres version-warning.rc -O coff -o version-warning.res
gcc -std=c11 -O2 -municode -mwindows -static-libgcc -Wall -Wextra -o qol-version-warning.exe version-warning.c version-warning.res -lcomctl32 -lshell32
```

When a native interface changes, give the DLL a new versioned filename and update the loader. Close every Quartus process that uses a binary before replacing it. Keep personal paths and generated research files out of the package.

## Test the package

Run `scripts/Install.ps1` with `-PrepareOnly -InstallRoot <isolated directory>` to download the tools and prepare an installation without changing Quartus startup. Quartus can stay open during this isolated preparation. Close it for a normal install, upgrade or uninstall.

Run `tests/Test-Package.ps1` with `-PreparedRoot` pointing to the prepared directory and `-QuartusRoot` pointing to a supported Quartus installation. The startup-hook tests use a temporary fake installation with copied DLLs and a synthetic startup file. They don't change the real startup file.

## Make a release

Update `VERSION` and the changelog, then test the package. Run `scripts/Build-Release.ps1` to create the release ZIP and checksums.

On untested Quartus builds, the installer requires the user to accept the version warning. It records both DLL hashes in `user/compatibility.dict` as data. That acknowledgement applies only to those binaries and doesn't bypass native interface checks.

Linux support needs a native bridge and startup integration for Linux. Changing the executable paths alone won't make the Windows package work there.
