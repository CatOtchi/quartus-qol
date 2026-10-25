# Quartus QOL

Slang diagnostics, Verible formatting, fuzzy completion and improved colors **inside Quartus's own editor**. No external editor or VS Code installation needed.

**Tested: Windows x64, Quartus Prime Lite 24.1std build 1077.** On other builds, the installer shows a warning with **Cancel** and **I understand and continue**. Continuing attempts an experimental installation; compatibility is not guaranteed. Linux is not supported yet.

![Slang diagnostic hover and syntax colors in Quartus's native editor](docs/demo-diagnostics.png)

![Typing se suggests serial_data in Quartus's native completion popup](docs/demo-completion.png)

These are actual Quartus screenshots using the included demo. The surrounding Quartus theme and font follow your existing settings.

## Download and install

1. Download the **QuartusQOL-…-windows-x64.zip** from [Releases](https://github.com/CatOtchi/quartus-qol/releases/latest) and extract it. A source ZIP or Git clone also works.
2. Close Quartus, then double-click **Install.cmd**. Internet access is needed on the first install.
3. The installer finds Quartus or asks for its folder. If its binaries differ from the tested build, choose **Cancel** to stop without changes or **I understand and continue** to try it experimentally. It downloads and verifies private copies of Slang, Verible, Python and Node—nothing needs to be on your PATH.
4. Approve the administrator prompt **if** Windows protects the Quartus installation folder.
5. Open Quartus normally and open a `.sv` or `.v` file. Save to format and check it.

Windows may show a warning because this small community project is unsigned. Downloads come from the upstream projects over HTTPS and their archive SHA-256 values are pinned in `dependencies.json`.

Files are installed under `%LOCALAPPDATA%\QuartusQOL`. You can delete the downloaded ZIP/folder after installation. After setup, the editor features run locally without network access or automatic updates.

On an untested build, the installer asks before changing anything:

![Untested version warning with Cancel and I understand and continue](docs/version-warning.png)

## What you get

- Red error, orange warning and blue information squiggles from Slang after save, with stacked diagnostic tooltips.
- Verible format on save: four-space indentation, 120-column limit, aligned declarations, ports, parameters and assignments.
- Fuzzy completion for names in the current file and common HDL keywords: `data` finds `serial_data`, `ksc` finds `key_code_synced`, and `ledr` finds `LEDR`. Matching is case-insensitive for all candidates; original spelling is preserved. Arrows select, Tab/Enter accepts, Escape dismisses.
- Syntax roles and matching block/bracket depth colors in a subdued Quartus palette.
- Readable dark Pin Planner assignment rows.
- Settings in the actual **Tools → Options** dialog:

| Page | Added setting |
| --- | --- |
| Text Editor → Autocomplete Text | QOL completion |
| Text Editor → Formatting | Format on save |
| Text Editor → Diagnostics | Slang checking and hover |
| Text Editor → Colors | Syntax and nesting colors |
| Pin Planner | Dark assignment table |

**OK** saves preferences; **Cancel** discards changes. Quartus's own autocomplete controls are separate. Completion is lexical, not type-aware member/port completion. Diagnostics check saved files; editing clears stale marks. Formatting stays undoable and results are discarded if newer edits would be overwritten.

Try [demo/qol_demo.sv](demo/qol_demo.sv). It intentionally contains an undeclared signal. See [the demo instructions](demo/README.md).

## Upgrade

Close Quartus. Download and extract a newer release, or `git pull` your clone, then run **Install.cmd** again. Open Quartus normally. The same installer updates the files and fetches changed dependencies while keeping `user/preferences.dict` and `user/config.tcl`.

No Git knowledge is needed. Keep a previous release ZIP if you want to reinstall an older version. All Quartus windows must be closed so Windows can release the loaded bridge DLLs.

## Uninstall

Close Quartus and run **Uninstall.cmd**, either from a download or `%LOCALAPPDATA%\QuartusQOL`. It removes only this installation's marked startup hook and keeps your settings and tools. Delete the installed folder afterward if you no longer want them.

## Advanced configuration

Copy the installed `user/config.example.tcl` to `user/config.tcl` to override include directories, defines, compiler flags or formatting options. Restart Quartus after editing it. Preferences from Tools → Options take precedence over feature defaults.

Custom location or Quartus path:

```powershell
.\scripts\Install.ps1 -QuartusRoot 'D:\altera_lite\24.1std\quartus' -InstallRoot 'D:\QuartusQOL'
.\scripts\Uninstall.ps1 -InstallRoot 'D:\QuartusQOL'
```

Use a local installation path without braces. Install for your own Windows account; the app and tools are per-user. Installing into one shared Quartus installation changes its startup file, so coordinate with other users of that installation.

## Troubleshooting and limits

- **Untested build:** accepting the installer warning records consent for that exact editor/Options DLL pair. Native signature and function checks still apply, so the extension may fail to start on incompatible interfaces. It may also crash; there is no guarantee of compatibility. After Quartus changes, rerun the installer to acknowledge the new build. Cancel, Escape and closing the dialog all cancel; Enter defaults to Cancel.
- **No startup features:** check `app/.runtime/startup-error.txt` under the installed folder. Installation only edits a short marked block in `quartus/common/tcl/internal/qui_init.tcl`; Quartus DLLs are never modified.
- **Download failure:** rerun the installer. Verified archives are cached; a checksum mismatch stops installation.
- **Project-specific errors:** sources, top entity, include paths and macros are read from the project. Files only referenced through QIP/generated IP may need explicit configuration.
- HDL source should be UTF-8/ASCII. Verilog/SystemVerilog are supported; VHDL is not. Slang and Quartus synthesis can report different issues.
- Completion skips files above 1 MiB; enhanced colors skip files above 4 MiB. Formatting preserves line endings and approximates caret/scroll position.
- This uses undocumented native Qt/Scintilla interfaces and is a small experimental project, not an official Altera extension. See [validation](docs/VALIDATION.md) for what has actually been checked.

## Source and licensing

MIT for this project's code; third-party components retain their own licences. See [THIRD_PARTY.md](THIRD_PARTY.md). Quartus itself is not included. Build instructions are in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).
