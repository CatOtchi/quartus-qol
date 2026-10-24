# Changelog

## 0.1.1

- On untested Quartus builds, show a version warning with Cancel and I understand and continue instead of refusing installation outright.
- Record acknowledgement for the exact editor/Options binaries; keep native interface checks active and require fresh acknowledgement after a binary change.
- Allow uninstalling the startup hook after Quartus updates, without requiring the old binary hashes.

## 0.1.0

First public Windows package for Quartus Prime Lite 24.1std build 1077.

- Slang diagnostics and stacked hover tooltips after save.
- Verible format on save with asynchronous results and stale-edit protection.
- Syntax roles, bracket/block depth colors and readable Pin Planner rows.
- Case-insensitive fuzzy lexical completion using the native popup.
- Feature switches in Quartus Tools → Options.
- Per-user install, verified automatic dependency downloads, repeatable upgrades and reversible startup hook.
