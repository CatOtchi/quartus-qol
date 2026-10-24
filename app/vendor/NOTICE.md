Syntax coloring dependencies (local copies, no runtime network access):

- `vscode-textmate` 9.3.2, Microsoft, MIT. Source: https://github.com/microsoft/vscode-textmate
- `vscode-oniguruma` 2.0.1, Microsoft, MIT plus bundled Oniguruma notices. Source: https://github.com/microsoft/vscode-oniguruma
- Verilog/SystemVerilog grammars and bracket configurations copied from the user's installed `mshr-h.veriloghdl` 1.29.0 extension. Source: https://github.com/mshr-h/vscode-verilog-hdl-support

Licenses remain in each dependency's directory. The grammar determines token scopes; `highlighter.cjs` maps those scopes to the Quartus palette in `theme.tcl`. Bracket colors use the copied language configuration's pair definitions and a local nesting stack. No VS Code editor UI is embedded or required.
