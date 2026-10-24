# Development

The `app` directory is the runtime payload. Tcl orchestrates asynchronous Python/Slang/Verible jobs; a persistent Node worker tokenizes source with the vendored TextMate grammar. `qol_native.c` registers a Tcl command and uses the embedded Scintilla/Qt controls. `qol_options.inc` implements the Options integration. `qol_pump.c` services Tcl timers on the existing GUI thread; `qol_worker.c` starts tools with clean DLL lookup and hidden windows.

Build the three helpers on Windows x64 with MinGW-w64 GCC:

```powershell
cd app
gcc -std=c11 -O2 -shared -static-libgcc -Wall -Wextra -o qolnative-v13.dll qol_native.c
gcc -std=c11 -O2 -shared -static-libgcc -Wall -Wextra -o qolpump.dll qol_pump.c
gcc -std=c11 -O2 -static-libgcc -municode -Wall -Wextra -o qolworker-v3.exe qol_worker.c
windres version-warning.rc -O coff -o version-warning.res
gcc -std=c11 -O2 -municode -mwindows -static-libgcc -Wall -Wextra -o qol-version-warning.exe version-warning.c version-warning.res -lcomctl32 -lshell32
```

Keep DLL filenames versioned when their native interface changes and update the loader. All Quartus processes using a binary must exit before it can be replaced. Avoid adding personal paths or generated research files.

The installer supports `-PrepareOnly -InstallRoot <isolated directory>` to download dependencies and stage a portable layout without touching Quartus startup. It permits an unrelated Quartus process to remain open only in that isolated mode. Normal installs/upgrades/uninstalls require Quartus to be closed.

Run `tests/Test-Package.ps1` with `-PreparedRoot` pointing to that layout and `-QuartusRoot` pointing to a supported installation. Hook tests operate on a temporary fake installation with copied DLLs and a synthetic startup file; the real startup file is untouched.

Run `scripts/Build-Release.ps1` to create the release ZIP and checksums. Bump `VERSION`, document changes and test before publishing. Untested binaries require explicit installer acknowledgement in `user/compatibility.dict`; this data-only consent matches both current DLL hashes and never skips native interface checks. Linux requires a separate native bridge and startup integration, not merely different executable paths.
