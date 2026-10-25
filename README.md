# Quartus QOL

I wanted formatting, error checking and decent autocomplete without having to leave Quartus, so this adds those to the editor that's already there.

You only need **Quartus and an internet connection for the installer**. It downloads Slang, Verible, Python and Node for you. You don't need VS Code or any of those tools installed beforehand, and it works offline once it's set up.

Tested on **Windows x64 with Quartus Prime Lite 24.1std build 1077**. If you have a different build, you'll get a warning and can either cancel or click **I understand and continue**. You're welcome to try it, but I can't guarantee it'll work. Linux isn't supported yet.

![Slang diagnostic hover in Quartus](docs/demo-diagnostics.png)

![Native completion suggestions in Quartus](docs/demo-completion.png)

The screenshots use the **Quartus Dark** editor preset. A fresh install starts with **Quartus (light)**, which looks like the usual Quartus editor, with extra colors for things like ports and nested blocks.

## Install

1. Download the Windows ZIP from [the latest release](https://github.com/CatOtchi/quartus-qol/releases/latest) and extract it.
2. Close Quartus and run **Install.cmd**.
3. It finds Quartus, or asks you where it's installed, then downloads the tools it needs. Approve the admin prompt if it needs permission to add the startup hook.
4. Open Quartus normally. Open a `.sv` or `.v` file and save it.

It installs into `%LOCALAPPDATA%\QuartusQOL`, so you can delete the folder you downloaded afterwards. Downloads come from the tools' own release pages and are checked against pinned SHA-256 hashes. Nothing gets added to your system PATH.

## What it adds

- **Error checking after save:** Slang draws red errors, orange warnings and blue notes. Hover over a marked line to see the messages. Multiple messages stack in the same tooltip.
- **Format on save:** Verible handles indentation and alignment. The defaults are four spaces, 120 columns, and aligned ports, declarations and assignments.
- **Autocomplete:** Names from the current file and common HDL keywords. Matching ignores case and works with parts of names or letters in order, so `data` finds `serial_data`, `ksc` finds `key_code_synced`, and `ledr` finds `LEDR`. Arrows select, Tab/Enter accepts and Escape closes it.
- **Coloring:** Different colors for syntax roles, plus matching colors for nested brackets and blocks. You can pick a preset or turn the enhanced coloring off.
- **Optional Pin Planner colors:** Use the editor's palette for the assignment rows. This is off by default.

Try [the demo file](demo/qol_demo.sv) if you want to see it working. `missing_signal` is deliberately wrong so there's an error to hover over.

## Colors and settings

Go to **Tools → Options → Text Editor → Colors** to pick an editor theme:

- **Quartus (light)** — The default. White background and familiar Quartus colors, extended for the extra syntax roles.
- **Quartus Dark** — The grey palette used in my screenshots and the original QOL setup.
- **Catppuccin Frappé**
- **Nord**
- **Tokyo Night**
- **Catppuccin Latte** — Light.
- **Tokyo Night Day** — Light.

**The dark menus, toolbars and other UI around the editor in my screenshots aren't supplied by this plugin.** That comes from my existing Quartus/Qt setup. These presets change the editor, and optionally the Pin Planner assignment table. They don't replace Quartus's whole UI theme or change your font.

The other switches are in Options too:

| Where | What |
| --- | --- |
| Text Editor → Autocomplete Text | QOL completion |
| Text Editor → Formatting | Format on save |
| Text Editor → Diagnostics | Checking and hover |
| Text Editor → Colors | Enhanced colors and the theme preset |
| Pin Planner | Use the editor theme for assignment rows |

Click **OK** to save or **Cancel** to leave things as they were. Turning enhanced colors off gives control back to Quartus's own color settings. Quartus's original autocomplete switches are separate from the QOL switch.

If you're upgrading from a release before the theme picker, it keeps the original dark palette. New installs get the light Quartus-style default.

## Updating or removing it

To update, close Quartus, download a newer ZIP and run its **Install.cmd** again. If you cloned the repo, `git pull` and rerun the installer. Your settings and selected theme are kept.

To uninstall, close Quartus and run **Uninstall.cmd**. It removes its startup hook but keeps your settings and downloaded tools. You can delete `%LOCALAPPDATA%\QuartusQOL` afterwards if you want those gone too.

## If something doesn't work

Other Quartus builds may have different internals. Accepting the version warning lets the installer try, but the bridge still checks the interfaces it uses and can refuse to load. It can also crash on an untested build. If Quartus changes, rerun the installer to acknowledge that build.

![Version warning](docs/version-warning.png)

If nothing starts, check `app/.runtime/startup-error.txt` inside the installed folder. If a download fails, rerun the installer; it keeps verified downloads so you don't need to start over.

Checking is for saved Verilog/SystemVerilog files, not VHDL. Slang and Quartus synthesis won't always report the same issues. Completion uses words from the file rather than compiler-resolved members or ports. Very large files skip completion or enhanced coloring.

Project source files, includes, macros and the top module are picked up automatically where possible. For generated IP or unusual projects, copy `user/config.example.tcl` to `user/config.tcl` in the installed folder and add your paths or overrides there. Restart Quartus after changing it.

This uses undocumented Quartus internals and isn't an official Altera plugin. The installer adds a marked block to `quartus/common/tcl/internal/qui_init.tcl`; it doesn't modify Quartus's DLLs. See [validation](docs/VALIDATION.md) for what's actually been tested, including the limits of the clean-machine testing.

## Source

[Build/development notes](docs/DEVELOPMENT.md), [third-party notices](THIRD_PARTY.md), [MIT licence](LICENSE). Quartus itself isn't included.
