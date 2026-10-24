# Third-party components

No Quartus/Altera binaries are distributed. Users must install Quartus themselves.

Bundled syntax components retain their licence files under `app/vendor`:

- [vscode-textmate](https://github.com/microsoft/vscode-textmate), 9.3.2, MIT.
- [vscode-oniguruma](https://github.com/microsoft/vscode-oniguruma), 2.0.1, MIT; includes Oniguruma notices.
- [mshr-h/vscode-verilog-hdl-support](https://github.com/mshr-h/vscode-verilog-hdl-support), 1.29.0 grammars and language configuration, MIT.

The installer downloads original upstream archives, not modified repackagings:

| Component | Version | Licence/source |
| --- | --- | --- |
| Slang | 11.0 | [MIT](https://github.com/MikePopoloski/slang/blob/v11.0/LICENSE) and upstream third-party components |
| Verible | v0.0-4294-gc1d8f5e8 | [Apache-2.0](https://github.com/chipsalliance/verible/blob/v0.0-4294-gc1d8f5e8/LICENSE) and upstream third-party components |
| CPython embedded | 3.13.7 | [Python licence](https://docs.python.org/3.13/license.html); archive includes LICENSE.txt |
| Node.js | 22.20.0 | [Node licence and notices](https://github.com/nodejs/node/blob/v22.20.0/LICENSE); included in upstream archive |

Download URLs and SHA-256 values are recorded in `dependencies.json`. Python and Node are private runtimes; the installer does not change system PATH or install pip/npm packages globally.

Native helpers are built with GCC/MinGW-w64 and static libgcc. GCC runtime parts are covered by the [GCC Runtime Library Exception](https://www.gnu.org/licenses/gcc-exception-3.1.html); the compiler itself is not distributed. Windows system libraries remain supplied by Windows.
