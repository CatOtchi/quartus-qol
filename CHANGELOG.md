# Changelog

## 0.3.0

- Dark editor presets also color Qt menus, toolbars, panels and dialogs. Light presets and disabling enhanced colors restore the original application stylesheet.
- Formatting options now include indentation width and line length. Diagnostics options include extra Slang warnings and hover delay.
- Advanced arguments remain in `user/config.tcl`. Changing the new controls preserves unrelated arguments.
- Cleaned up the documentation and updated the installation test notes.

## 0.2.0

- Added a theme dropdown under Tools → Options → Text Editor → Colors. It offers Quartus, Quartus Dark, Catppuccin Frappé, Nord, Tokyo Night, Catppuccin Latte and Tokyo Night Day.
- New installs use the light Quartus palette with Pin Planner colors off. Upgrades keep the original dark palette until you select another preset.
- Pin Planner can use the selected editor palette. Themes don't change the font or the rest of Quartus's UI.

## 0.1.1

- Added a warning on untested Quartus builds with Cancel and I understand and continue buttons. Earlier versions refused to install on those builds.
- The installer records acknowledgement for the exact editor and Options DLLs. Native interface checks still run. If either DLL changes, the user must accept the warning again.
- The uninstaller can remove the startup hook after a Quartus update without requiring the old DLL hashes.

## 0.1.0

First public Windows package for Quartus Prime Lite 24.1std build 1077.

- Slang checks files after save and shows messages in hover tooltips.
- Verible formats on save in the background. QOL discards results if the source has changed since formatting started.
- The editor colors syntax roles and nested brackets and blocks. Pin Planner has optional row colors.
- Autocomplete uses the native popup and matches parts of names without regard to case.
- Settings appear in Quartus Tools → Options.
- The installer downloads and verifies tools for the current user. It preserves settings during upgrades and adds a startup hook that the uninstaller can remove.
