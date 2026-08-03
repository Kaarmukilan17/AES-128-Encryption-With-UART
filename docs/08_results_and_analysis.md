# 08 — Results & Analysis

## Resource Utilization

From `top.fit.summary` (Quartus Prime 22.1std.2 Build 922, compiled Wed May 6 19:15:25 2026):

| Resource | Used | Available | % |
|----------|------|-----------|---|
| Total logic elements | 6,485 | 114,480 | 6% |
| — Total combinational functions | 6,440 | | |
| — Dedicated logic registers | 567 | | |
| Total pins | 93 | 529 | 18% |
| Embedded multipliers | 0 | | |
| PLLs | 0 | | |

The iterative architecture pays off: a full AES-128 core plus UART, display and debug logic fits in 6% of the Cyclone IV E.

## Timing Analysis — the Negative Slack Is Expected

STA reports negative setup slack on CLOCK_50 (−3.958 ns). **This is expected and not a problem:**

- The AES combinational path (SubBytes LUT chain → ShiftRows → MixColumns → AddRoundKey, plus the fully combinational key schedule) is too long to close timing at 50 MHz automatically.
- But the AES datapath is **not clocked by CLOCK_50** — it runs on the manual button clock (SW17 → debounce). Between human button presses (≥ ~100 ms) the combinational path has effectively unlimited time to settle; it only needs ~5 ns.
- The CLOCK_50 domain drives only the UART, display and debug logic, which all close timing comfortably.

## Hardware Verification

The design was compiled and verified on the DE2-115 board: plaintexts entered over UART at 9600 8N1, keys selected via SW[3:0], 11 manual clock presses per encryption, and the ciphertext read from the 7-segment display was compared against the verified table in [07_test_vectors.md](07_test_vectors.md) (NIST vectors including index 0 — `69C4E0D86A7B0430D8CDB78070B4C55A` — and the PyCryptodome-verified custom vectors).

## Design Challenges Solved

See the detailed write-ups in the other docs:

1. Metastability on UART_RXD → 2-FF synchronizer ([03](03_uart_input.md))
2. Mechanical switch bounce → 20 ms debounce counter ([04](04_display_system.md))
3. Single-cycle pulses invisible to the eye → ~21 ms pulse stretching ([04](04_display_system.md))
4. Hardwired `.rst(1'b0)` in the original UART → proper reset chain ([03](03_uart_input.md))
5. Clock counter overrunning after done → `.rst(done | reset)` ([04](04_display_system.md))
6. Active-low 7-segment encoding ([04](04_display_system.md))
7. `$readmemh("key.txt")` path dependency → key.txt kept in the Quartus working directory (this doc, below)

### key.txt Path Dependency

`$readmemh("key.txt", mem)` resolves relative to the Quartus project directory. Moving the project without the file breaks synthesis (ROM initializes to X). That is why `key.txt` is duplicated in `quartus/` alongside `top.qsf`; the canonical copy lives in `data/`. If you relocate the project, keep them in sync.

## Known Limitations

- **No UART TX** — the ciphertext cannot be echoed back to the terminal; it must be read from the 7-segment display.
- **Manual clock only** — the AES core is not run at 50 MHz (by design, for observability).
- **No AES decryption** — encryption only.
- **Static key ROM** — no runtime key loading; keys are baked in at synthesis from key.txt.
- **STA negative slack** on the AES path (expected, see above — not a bug).

## Future Work

- UART TX to echo the ciphertext back to the terminal
- Pipelined 11-stage architecture (already designed separately) for high throughput at 50 MHz+
- AES-256 extension (14 rounds, 240-byte key schedule)
- CBC/CTR mode wrapper around the ECB core
- LCD display instead of 7-segment scrolling
