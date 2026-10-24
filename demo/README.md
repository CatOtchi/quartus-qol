# Demo

Open `qol_demo.sv` in Quartus after installing QOL. There is no board or FPGA compilation requirement for this standalone example.

1. Save: Verible formats the file and Slang underlines `missing_signal`.
2. Hover over that name to see its diagnostic.
3. Replace it with `SW[0]` and save to clear the error.
4. On a temporary blank line, try `data`, `ksc` or `ledr` to see fuzzy completion, then press Escape and undo your test input.
5. Open Tools → Options → Text Editor to find the feature switches.

`missing_signal` is deliberately invalid. It is not a working hardware design.
