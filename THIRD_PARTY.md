# Third-party components

This package doesn't include Quartus or Altera binaries. Users must install Quartus themselves.

Bundled syntax components retain their licence files under `app/vendor`:

- [vscode-textmate](https://github.com/microsoft/vscode-textmate), 9.3.2, MIT.
- [vscode-oniguruma](https://github.com/microsoft/vscode-oniguruma), 2.0.1, MIT. Includes Oniguruma notices.
- [mshr-h/vscode-verilog-hdl-support](https://github.com/mshr-h/vscode-verilog-hdl-support), 1.29.0 grammars and language configuration, MIT.

The installer downloads these tools' original release archives:

| Component | Version | Licence/source |
| --- | --- | --- |
| Slang | 11.0 | [MIT](https://github.com/MikePopoloski/slang/blob/v11.0/LICENSE) and upstream third-party components |
| Verible | v0.0-4294-gc1d8f5e8 | [Apache-2.0](https://github.com/chipsalliance/verible/blob/v0.0-4294-gc1d8f5e8/LICENSE) and upstream third-party components |
| CPython embedded | 3.13.7 | [Python licence](https://docs.python.org/3.13/license.html), also included as LICENSE.txt in the archive |
| Node.js | 22.20.0 | [Node licence and notices](https://github.com/nodejs/node/blob/v22.20.0/LICENSE), also included in the archive |

`dependencies.json` records the download URLs and SHA-256 hashes. The installer keeps its own copies of Python and Node. It doesn't change the system PATH or install pip or npm packages globally.

The native helpers are built with MinGW-w64 GCC and statically linked libgcc. The GCC runtime parts are covered by the [GCC Runtime Library Exception](https://www.gnu.org/licenses/gcc-exception-3.1.html). This package doesn't include the compiler. Windows supplies the system libraries.

Editor presets use colors from the [Catppuccin palette](https://github.com/catppuccin/palette), [Nord](https://github.com/nordtheme/nord) and [Tokyo Night](https://github.com/folke/tokyonight.nvim). Catppuccin and Nord use the MIT licence. Tokyo Night uses Apache-2.0. Their licence texts are in `app/vendor/palettes`.

QOL assigns those colors to its syntax roles and adjusts a few colors for contrast. These presets don't reproduce every detail of the original editor themes. Quartus and Quartus Dark are this project's palettes.
