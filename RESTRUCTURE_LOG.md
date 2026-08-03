# Restructure Log — 2026-07-12

Record of the project restructuring executed by Claude Code from
`Other_docs/CLAUDE_CODE_HANDOFF.md`. Kept for future reference.

## What was done

### Structure
- Created `src/{aes,uart,display,debug,utils}`, `quartus/`, `data/`,
  `docs/images/{rtl,sim,board}`, `sim/` in the project root.
- Created `.gitignore` (ignores Quartus `db/`, `incremental_db/`, report files,
  backups; keeps `.sof` and `.cdf`).

### Module split (no logic changes — extracted verbatim)
All 21 modules extracted into individual files:

- From `top.v` (12 files):
  - `src/top.v` — top module only (stripped)
  - `src/debug/debug_led_block.v`, `src/debug/clk_counter.v`
  - `src/uart/uart_rx_128.v`, `src/uart/uart_rx.v`
  - `src/display/top_128bit_display.v`, `src/display/eight_sevenseg_32bit.v`,
    `src/display/hex_to_7seg.v`
  - `src/utils/debounce.v`, `src/utils/edge_detector.v`,
    `src/utils/counter2_up.v`, `src/utils/mux4x1_32bit.v`
- From `aes_core.v` (8 files):
  - `src/aes/aes_core.v`, `aes_fsm.v`, `aes_datapath.v`, `aes_keyschedule.v`,
    `aes_mixcolumns.v`, `aes_shiftrows.v`, `aes_subbytes.v`, `aes_sbox.v`
- `key_rom128.v` → `src/aes/key_rom128.v` (verbatim)

Verified programmatically: 21 `.v` files in `src/`, and every file's code
matches the original sources character-for-character (whitespace/comment
banners aside).

### Quartus
- `top.qsf` and `top.qpf` copied to `quartus/`.
- In `quartus/top.qsf`: the 3 old `VERILOG_FILE` lines replaced with the
  21 new `../src/...` paths.
- `key.txt` copied into `quartus/` so `$readmemh("key.txt")` keeps working
  (path resolves relative to the Quartus project directory).

### Data
- `key.txt` and `data.txt` copied to `data/`.
- New `data/expected.txt` written with the 16 corrected ciphertexts
  (PyCryptodome AES-128-ECB verified). The original misspelled `expcetd.txt`
  had 7 wrong rows (rows 2, 4, 5, 12, 13, 14, 15 — 0-indexed).

### Documentation
- Wrote all 8 docs: `docs/01_architecture.md` … `docs/08_results_and_analysis.md`.
- Wrote `README.md` and `CONTRIBUTORS.md`.

## Things to know

1. **The handoff file wasn't at the root** — it was at
   `Other_docs/CLAUDE_CODE_HANDOFF.md`. Found and used it.
2. **Copied instead of moved** — the original `uart_aes_with_debug_led_n_synchr/`
   folder is completely untouched. It's now redundant (superseded by `src/` +
   `quartus/`) and can be deleted once the new `quartus/top.qpf` compiles
   cleanly, but it holds the only compiled, working Quartus project until then.
3. **Code quirk preserved verbatim** (per the "do not change Verilog" rule):
   in `top.v`, the `done` signal is used (`.done(done)`, `LEDG[7] = done`) but
   never declared — it works only via Verilog's implicit-wire rule. Worth
   fixing someday, but left exactly as-is.
4. **One comment adjusted**: the original `aes_core.v` file-header banner said
   `aes_top.v — AES-128 full implementation`, which would be misleading in the
   split-out wrapper file, so that banner now reads
   `aes_core.v — AES-128 wrapper`. All module code itself is untouched.
5. **Recompile note**: `PROJECT_OUTPUT_DIRECTORY` is still `output_files`, so a
   fresh compile from `quartus/` will create `quartus/output_files/`. The old
   compiled `.sof` remains in the legacy folder — copy it over to program the
   board before recompiling.

## Next step
Open `quartus/top.qpf` in Quartus and run Analysis & Synthesis once to confirm
the new paths resolve.
