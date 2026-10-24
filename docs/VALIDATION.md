# Validation of 0.1.0

Checked on Windows with Quartus Prime Lite 24.1std build 1077. This is a small community release, not a certification across Windows machines or Quartus versions.

## Package and installer

- Downloaded private Python 3.13.7, Node 22.20.0, Slang 11.0 and the pinned Verible Windows archive from their original upstream URLs. All four archive SHA-256 values matched the manifest. Node's hash also matched its published SHASUMS256.txt; Slang/Verible hashes matched GitHub release-asset digests.
- Prepared a new directory with a space in its path without using system Python, Node, Slang or Verible.
- Re-ran the installer with Windows PowerShell 5.1: cached tools were reused; user preferences/config were preserved; no nested scripts directory appeared.
- Tested PowerShell parsing and the package checks under PowerShell 5.1 and PowerShell 7.
- Tested hook installation twice against a synthetic Quartus startup file: exactly one block remained. Uninstall preserved an unrelated customization and refused to remove a hook for another installation. Tests used copied compatibility DLLs in a fake directory; they did not alter the real Quartus startup file.
- Ran the complete normal install, upgrade and uninstall scripts against that synthetic installation under Windows PowerShell 5.1, including installation records and user-config preservation.
- The real supported editor and Options DLL hashes passed compatibility validation.

## Runtime checks

- Tcl tests passed for preference validation, data-only persistence, toggling features and cleanup.
- Completion tests passed for prefixes, substrings, ordered abbreviations, case-insensitive matching, candidate ranking/limits, and excluding comments, strings, escaped identifiers and literals.
- TextMate tests passed for symbol roles, nested block/bracket colors, multiline strings/comments, UTF-8/CRLF, incomplete source and mismatch recovery.
- The private embedded Python invoked the actual downloaded Slang/Verible executables: an undeclared signal produced an error, and deliberately unformatted source produced formatted output.
- Loaded the isolated installed layout into a separate Quartus GUI session. Confirmed native bridge 13, portable paths, syntax colors, real error squiggles and a visible diagnostic hover.
- In the GUI, typed `ledr`, `ksc` and `data`, then accepted each with Tab. The inserted text was respectively `LEDR`, `key_code_synced` and `serial_data`.
- Restored the scratch buffer after the completion checks and confirmed it matched disk with no unsaved modification. Screenshots in this repository came from that separate demo session.

## Limits of this validation

The package was tested in an isolated directory on the development PC, not a clean Windows VM or a friend's computer. The real protected-directory UAC installation path was not exercised for this package; reversible hook editing was tested against a synthetic installation. The existing development installation was left in place. A first installation on another PC remains useful validation.

The pinned Verible archive is published under `v0.0-4294-gc1d8f5e8`; its executable reports `v0.0-4222-g9e422385`. The downloaded archive's checksum matches the upstream release asset. The package pins the archive exactly rather than silently selecting a different build.

Other Quartus editions/builds, Linux, VHDL and multi-user shared installations have not been validated.

## 0.1.1 compatibility flow

- Logic tests cover the tested build without a warning, Cancel, Continue, exact-pair consent and invalidating consent when either binary changes.
- Tcl tests verify that runtime consent is parsed as data and applies only to the acknowledged pair. Native signature/export checks remain enabled.
- Inspected the native Windows warning with a synthetic version number. Both labels and warning text were visible; Continue returned acknowledgement and Cancel returned refusal through the installer helper. This was a dialog-only test and did not install against a different Quartus version.
- Accepting the warning has not been tested against an actual different Quartus build; it permits an experimental attempt, not a compatibility claim.
