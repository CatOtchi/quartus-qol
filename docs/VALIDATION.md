# Validation notes

These checks ran on the development PC with Windows x64 and Quartus Prime Lite 24.1std build 1077. They don't establish compatibility with other PCs or Quartus builds.

## 0.3.0 UI and settings checks

- Native bridge 15 builds with GCC warnings enabled.
- Automated palette tests check the generated dark UI stylesheet and requests to restore the original for light presets or disabled colors. They check that unchanged themes don't reapply the stylesheet on every poll. These tests stub native calls and don't establish the appearance of actual controls.
- Settings tests cover numeric limits, saved preferences, Verible indentation and line length, the Slang extra-warning switch and native hover delay.
- The isolated installation passes the package checks with its private tools.
- On October 29, 2026, a separate Quartus demo loaded native bridge 15. The Formatting page showed indentation and line-length controls. The Diagnostics page showed the extra-warning switch and hover delay.
- Clicking OK saved two-space indentation, a 100-column limit, extra warnings off and a 250 ms hover delay. The saved preferences and runtime arguments matched those values. Saving the demo then produced two-space indentation and still reported the intentional undeclared-signal error.
- Nord colored the main window, menus, panels and Options dialog. Selecting Tokyo Night Day and clicking Cancel left Nord active. Selecting it again and clicking OK restored the exact application stylesheet captured before the test. Theme changes left the source buffer unchanged.
- The tested Options dialog has OK, Cancel and Help buttons, with no visible Apply button. No live Apply-button test was possible.
- The demo was returned to Quartus Dark, four-space indentation, 120 columns, extra warnings on and a 400 ms hover delay. The everyday installation's preferences were unchanged.
- These live checks ran on a PC with Windows dark mode enabled. A separate PC with Windows light mode still needs testing. Custom-drawn views and Windows-native dialogs weren't checked.

## 0.2.0 theme checks

- Automated tests check that all seven palettes have valid colors for each syntax role and nesting depth. With editor calls stubbed, they check the requested background, syntax and Pin Planner colors. They also check that theme changes don't request font or source changes.
- Preference tests cover theme selection, saved settings, invalid values and migration of older settings to Quartus Dark. They check that new installs default to Quartus light with Pin Planner colors off.
- A separate Quartus preview loaded native bridge 14 with a light editor. The existing Text Editor → Colors page showed the dropdown and all seven presets. A startup timing fix prevented QOL from adding a duplicate Text Editor category before Quartus had created its own.
- Selecting Nord and clicking OK saved `theme nord`, changed the editor background to the expected color and left the source buffer unchanged.
- The live test stopped before checking Cancel and the remaining light presets. Automated tests cover the related settings and palette logic, but those UI checks still need a live test.

On October 25, 2026, the packaged 0.2.0 installer replaced the older development setup on this PC. The protected startup-hook update completed through the Windows administrator prompt. Checks confirmed the installed native DLL matched the package, the formatting configuration was unchanged, and all six feature switches remained on with `theme quartus_dark`. This installation check didn't include another live editor session.

## Package and installer

- Downloaded Python 3.13.7, Node 22.20.0, Slang 11.0 and the pinned Verible Windows archive from their release URLs. All four SHA-256 hashes matched `dependencies.json`. Node's hash also matched its published SHASUMS256.txt. Slang and Verible hashes matched the GitHub release asset digests.
- Prepared an installation in a new directory with a space in its path. It used its own copies of Python, Node, Slang and Verible.
- Reran the installer with Windows PowerShell 5.1. It reused cached tools, preserved user preferences and configuration, and didn't create a nested scripts directory.
- Tested PowerShell parsing and the package checks under PowerShell 5.1 and PowerShell 7.
- Installed the hook twice in a synthetic Quartus startup file. Exactly one block remained. Uninstall preserved an unrelated customization and refused to remove a hook belonging to another installation. These tests used copied DLLs in a fake directory and didn't change the real startup file.
- Ran the normal install, upgrade and uninstall scripts against the synthetic installation under Windows PowerShell 5.1. Checks covered installation records and preservation of user configuration.
- The supported editor and Options DLL hashes passed the compatibility check.

## Runtime checks

- Tcl tests passed for preference validation, saving preferences as data, feature switches and cleanup.
- Completion tests passed for prefixes, substrings, ordered abbreviations, case-insensitive matching, suggestion order and limits. They also checked that completion excludes comments, strings, escaped identifiers and literals.
- TextMate tests passed for symbol roles, nested blocks and brackets, multiline strings and comments, UTF-8 text, CRLF line endings, incomplete source and recovery from mismatched brackets.
- The installed Python ran the downloaded Slang and Verible executables. An undeclared signal produced an error. Deliberately unformatted source produced formatted output.
- The initial package loaded in a separate Quartus session with native bridge 13 and tool paths inside its installation directory. Syntax colors, error squiggles and diagnostic hover messages appeared in the editor.
- In the GUI, typed `ledr`, `ksc` and `data`, then accepted each with Tab. The inserted text was respectively `LEDR`, `key_code_synced` and `serial_data`.
- After the completion checks, the scratch buffer was restored and matched the file on disk with no unsaved changes. The repository screenshots came from the separate demo session.

## Limits of this validation

The package has been tested in isolated directories and installed on the development PC. It hasn't been tested on a clean Windows VM or a friend's computer. A successful install here doesn't prove that a first install on another PC will work.

The pinned Verible archive is published under `v0.0-4294-gc1d8f5e8`, but its executable reports `v0.0-4222-g9e422385`. The archive's checksum matches the release asset. The package uses that pinned archive.

Other Quartus editions and builds, Linux and shared installations for multiple users haven't been tested. QOL doesn't provide VHDL checking.

## 0.1.1 compatibility flow

- Logic tests cover the supported build without a warning, Cancel, Continue and acknowledgement for a specific pair of DLLs. They check that acknowledgement expires when either DLL changes.
- Tcl tests verify that the loader reads acknowledgement as data and accepts only the recorded DLL pair. Native signature and export checks remain enabled.
- The native Windows warning was tested with a synthetic version number. The text and both buttons were visible. Continue returned acknowledgement and Cancel returned refusal through the installer helper. This test didn't install QOL against a different Quartus version.
- No live test has accepted the warning on a different Quartus build. Accepting it allows an experimental installation, but doesn't establish compatibility.
