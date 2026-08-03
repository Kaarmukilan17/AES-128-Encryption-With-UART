# CLAUDE CODE HANDOFF — AES-128 UART FPGA Project
# Complete instructions for restructuring and documenting this project
# Read this entire file before doing anything. Then execute in order.

---

## CONTEXT

This is the final working non-pipelined AES-128 encryption accelerator
implemented on the Altera DE2-115 FPGA (Cyclone IV E, EP4CE115F29C7).
Compiled and verified on hardware. Quartus Prime 22.1 std.

**Architecture: Iterative FSM-based (NOT pipelined)**
- `aes_fsm` controls round sequencing: IDLE → INIT → ROUND → FINAL_ROUND → DONE_ST
- `aes_datapath` is one shared combinational round, reused 11 times
- One manual button press = one clock cycle = one round
- 11 button presses → done signal fires → ciphertext ready

**Resource utilization (from top.fit.summary):**
- Total logic elements: 6,485 / 114,480 (6%)
- Total combinational functions: 6,440
- Dedicated logic registers: 567
- Total pins: 93 / 529 (18%)
- Embedded multipliers: 0
- PLLs: 0

**Compiled:** Wed May 6 19:15:25 2026
**Tool:** Quartus Prime 22.1std.2 Build 922

---

## CURRENT FILE STATE

The project currently has 3 source files with ALL modules crammed together:

### top.v contains these modules:
1. `top`                  — master integrator
2. `debug_led_block`      — LEDR debug with pulse stretching
3. `clk_counter`          — AES clock press counter
4. `uart_rx_128`          — 32-char hex accumulator → 128-bit latch
5. `uart_rx`              — byte-level UART FSM
6. `top_128bit_display`   — display subsystem top
7. `debounce`             — mechanical switch glitch filter
8. `edge_detector`        — rising edge → single pulse
9. `counter2_up`          — 2-bit scroll counter
10. `mux4x1_32bit`        — 32-bit 4:1 segment selector
11. `eight_sevenseg_32bit`— 8-digit hex driver
12. `hex_to_7seg`         — nibble to 7-seg encoding (active-low)

### aes_core.v contains these modules:
13. `aes_core`            — AES wrapper (instantiates FSM + datapath + keyschedule)
14. `aes_fsm`             — 5-state FSM controlling round sequencing
15. `aes_datapath`        — single shared round: subbytes→shiftrows→mixcols→addrk
16. `aes_keyschedule`     — combinational key expansion, produces rkey_flat[1407:0]
17. `aes_mixcolumns`      — GF(2^8) column mixing with xtime function
18. `aes_shiftrows`       — cyclic byte reordering (pure wire reassignment)
19. `aes_subbytes`        — 16x parallel S-Box via generate loop
20. `aes_sbox`            — 256-entry substitution ROM

### key_rom128.v contains:
21. `key_rom128`          — 16-entry × 128-bit key ROM, $readmemh("key.txt")

**Total: 21 modules across 3 files**

---

## TARGET FOLDER STRUCTURE

Create this exact structure in the project root:

```
AES-128-UART-FPGA/
│
├── README.md
├── CONTRIBUTORS.md
├── .gitignore
│
├── src/
│   ├── top.v                          ← ONLY the top module (stripped)
│   │
│   ├── aes/
│   │   ├── aes_core.v                 ← wrapper module only
│   │   ├── aes_fsm.v                  ← FSM module only
│   │   ├── aes_datapath.v             ← datapath module only
│   │   ├── aes_keyschedule.v          ← key schedule module only
│   │   ├── aes_subbytes.v             ← subbytes module only
│   │   ├── aes_sbox.v                 ← sbox module only
│   │   ├── aes_shiftrows.v            ← shiftrows module only
│   │   └── aes_mixcolumns.v           ← mixcolumns module only
│   │
│   ├── uart/
│   │   ├── uart_rx.v                  ← byte-level receiver
│   │   └── uart_rx_128.v              ← 128-bit accumulator
│   │
│   ├── display/
│   │   ├── top_128bit_display.v       ← display subsystem top
│   │   ├── eight_sevenseg_32bit.v     ← 8-digit driver
│   │   └── hex_to_7seg.v              ← nibble encoder
│   │
│   ├── debug/
│   │   ├── debug_led_block.v          ← LEDR debug block
│   │   └── clk_counter.v              ← AES clock counter
│   │
│   └── utils/
│       ├── debounce.v                 ← glitch filter
│       ├── edge_detector.v            ← edge pulse
│       ├── counter2_up.v              ← 2-bit counter
│       └── mux4x1_32bit.v             ← 4:1 mux
│
├── quartus/
│   ├── top.qsf                        ← pin assignments (update file paths)
│   └── top.qpf                        ← project file
│
├── data/
│   ├── key.txt                        ← 16 × 128-bit keys (CRITICAL: Quartus reads this)
│   ├── data.txt                       ← 16 sample plaintexts
│   └── expected.txt                   ← corrected verified ciphertexts
│
├── docs/
│   ├── images/
│   │   ├── rtl/                       ← RTL screenshots from Quartus
│   │   ├── sim/                       ← ModelSim waveform screenshots
│   │   └── board/                     ← board photos with annotations
│   │
│   ├── 01_architecture.md
│   ├── 02_aes_core.md
│   ├── 03_uart_input.md
│   ├── 04_display_system.md
│   ├── 05_pin_assignments.md
│   ├── 06_how_to_use.md
│   ├── 07_test_vectors.md
│   └── 08_results_and_analysis.md
│
└── sim/
    └── (place any testbench .v files here)
```

---

## STEP 1: CREATE .gitignore

Create `.gitignore` in project root with this content:

```gitignore
# Quartus generated files
db/
incremental_db/
output_files/*.rpt
output_files/*.smsg
output_files/*.summary
output_files/*.done
output_files/*.eda.rpt
output_files/*.flow.rpt
output_files/*.jdi
output_files/*.pin
output_files/*.sld
output_files/*.vo
simulation/

# Keep the .sof (programming file) and .cdf
!output_files/*.sof
!output_files/*.cdf

# Backup files
*.bak
*.bak2

# OS files
.DS_Store
Thumbs.db

# Quartus workspace
*.qws
```

---

## STEP 2: SPLIT THE MODULES

### From top.v — extract each module into its own file

Each extraction is just cut-and-paste of the module block verbatim.
The `top` module stays in `src/top.v`.

**src/utils/debounce.v** — extract `module debounce` ... `endmodule`
**src/utils/edge_detector.v** — extract `module edge_detector` ... `endmodule`
**src/utils/counter2_up.v** — extract `module counter2_up` ... `endmodule`
**src/utils/mux4x1_32bit.v** — extract `module mux4x1_32bit` ... `endmodule`
**src/uart/uart_rx.v** — extract `module uart_rx` ... `endmodule`
**src/uart/uart_rx_128.v** — extract `module uart_rx_128` ... `endmodule`
**src/display/hex_to_7seg.v** — extract `module hex_to_7seg` ... `endmodule`
**src/display/eight_sevenseg_32bit.v** — extract `module eight_sevenseg_32bit` ... `endmodule`
**src/display/top_128bit_display.v** — extract `module top_128bit_display` ... `endmodule`
**src/debug/debug_led_block.v** — extract `module debug_led_block` ... `endmodule`
**src/debug/clk_counter.v** — extract `module clk_counter` ... `endmodule`

### From aes_core.v — extract each module

**src/aes/aes_core.v** — extract `module aes_core` ... `endmodule` (the wrapper only)
**src/aes/aes_fsm.v** — extract `module aes_fsm` ... `endmodule`
**src/aes/aes_datapath.v** — extract `module aes_datapath` ... `endmodule`
**src/aes/aes_keyschedule.v** — extract `module aes_keyschedule` ... `endmodule`
**src/aes/aes_mixcolumns.v** — extract `module aes_mixcolumns` ... `endmodule`
**src/aes/aes_shiftrows.v** — extract `module aes_shiftrows` ... `endmodule`
**src/aes/aes_subbytes.v** — extract `module aes_subbytes` ... `endmodule`
**src/aes/aes_sbox.v** — extract `module aes_sbox` ... `endmodule`

### key_rom128.v stays as is, move to:
**src/aes/key_rom128.v** — copy verbatim

---

## STEP 3: UPDATE top.qsf

After splitting, add all new file paths to top.qsf.
Replace the existing VERILOG_FILE assignments with:

```
set_global_assignment -name VERILOG_FILE ../src/top.v
set_global_assignment -name VERILOG_FILE ../src/aes/aes_core.v
set_global_assignment -name VERILOG_FILE ../src/aes/aes_fsm.v
set_global_assignment -name VERILOG_FILE ../src/aes/aes_datapath.v
set_global_assignment -name VERILOG_FILE ../src/aes/aes_keyschedule.v
set_global_assignment -name VERILOG_FILE ../src/aes/aes_subbytes.v
set_global_assignment -name VERILOG_FILE ../src/aes/aes_sbox.v
set_global_assignment -name VERILOG_FILE ../src/aes/aes_shiftrows.v
set_global_assignment -name VERILOG_FILE ../src/aes/aes_mixcolumns.v
set_global_assignment -name VERILOG_FILE ../src/aes/key_rom128.v
set_global_assignment -name VERILOG_FILE ../src/uart/uart_rx.v
set_global_assignment -name VERILOG_FILE ../src/uart/uart_rx_128.v
set_global_assignment -name VERILOG_FILE ../src/display/top_128bit_display.v
set_global_assignment -name VERILOG_FILE ../src/display/eight_sevenseg_32bit.v
set_global_assignment -name VERILOG_FILE ../src/display/hex_to_7seg.v
set_global_assignment -name VERILOG_FILE ../src/debug/debug_led_block.v
set_global_assignment -name VERILOG_FILE ../src/debug/clk_counter.v
set_global_assignment -name VERILOG_FILE ../src/utils/debounce.v
set_global_assignment -name VERILOG_FILE ../src/utils/edge_detector.v
set_global_assignment -name VERILOG_FILE ../src/utils/counter2_up.v
set_global_assignment -name VERILOG_FILE ../src/utils/mux4x1_32bit.v
```

NOTE: key.txt must remain accessible from the Quartus project working directory.
Copy data/key.txt to the quartus/ folder OR update the $readmemh path in key_rom128.v.

---

## STEP 4: CORRECTED data/expected.txt

The original expected.txt had wrong values. Use these verified outputs
(computed with PyCryptodome AES-128-ECB, cross-checked against NIST):

```
69C4E0D86A7B0430D8CDB78070B4C55A
66E94BD4EF8A2C3B884CFA59CA342B2E
BCBF217CB280CF30B2517052193AB979
A1F6258C877D5FCD8964484538BFC92C
3F5B8CC9EA855A0AFA7347D23E8D664E
8DF4E9AAC5C7573A27D8D055D6E4D64B
0A940BB5416EF045F1C39458C653EA5A
3AD77BB40D7A3660A89ECAF32466EF97
F5D3D58503B9699DE785895A96FDBAAF
43B1CD7F598ECE23881B00E3ED030688
7B0C785E27E8AD3F8223207104725DD4
A1F6258C877D5FCD8964484538BFC92C
FFA3C7ED04710B98067DAE6815E2751F
C6BFD3CEEBCFD5406E5B3E0BAFB9D1B5
2E3A7007E0696FED74CDF0E5D2E4651D
D6F13021DF12A669813A50D15D92A629
```

Rows 2, 4, 5, 12, 13, 14, 15 were wrong in the original file.
Rows 0, 1, 3, 6, 7, 8, 9, 10, 11 were already correct (NIST vectors).

---

## STEP 5: PIN ASSIGNMENTS REFERENCE

Extracted from top.qsf. Use in docs/05_pin_assignments.md.

### Control Inputs (named ports — NOT SW bus)
| Signal      | Comment in code | Quartus Pin | DE2-115 Physical |
|-------------|----------------|-------------|-----------------|
| CLOCK_50    | system clock   | PIN_Y2      | CLOCK_50        |
| UART_RXD    | serial input   | PIN_G12     | UART_RXD        |
| clk_btn     | //17           | PIN_Y23     | SW17            |
| reset       | //10           | PIN_AC24    | SW10            |
| btn         | //key0         | PIN_M23     | KEY0            |
| debug_sel   | //7            | PIN_AB26    | SW7             |
| start       | //5            | PIN_AC26    | SW5             |

NOTE: clk_btn, reset, debug_sel, start are mapped to individual SW pins
(SW17, SW10, SW7, SW5) not through the SW[3:0] bus. The SW[3:0] bus
(SW[0..3]) is used ONLY for key ROM address.

### Key ROM Address
| Signal  | Pin     | Physical |
|---------|---------|----------|
| SW[0]   | PIN_AB28| SW0      |
| SW[1]   | PIN_AC28| SW1      |
| SW[2]   | PIN_AC27| SW2      |
| SW[3]   | PIN_AD27| SW3      |

SW[3:0] = 0000 → key index 0, SW[3:0] = 0001 → key index 1, etc.

### LEDG Output
| Signal      | Pin     | Function                        |
|-------------|---------|----------------------------------|
| LEDG[0]     | PIN_E21 | status_led[0] — display segment |
| LEDG[1]     | PIN_E22 | status_led[1] — display segment |
| LEDG[2]     | PIN_E25 | clk_count[0]                    |
| LEDG[3]     | PIN_E24 | clk_count[1]                    |
| LEDG[4]     | PIN_H21 | clk_count[2]                    |
| LEDG[5]     | PIN_G20 | clk_count[3]                    |
| LEDG[6]     | PIN_G22 | clk_count[4]                    |
| LEDG[7]     | PIN_G21 | done signal                     |

### LEDR Debug Output
| Signal      | Pin     | Function                                        |
|-------------|---------|--------------------------------------------------|
| LEDR[0]     | PIN_G19 | (mapped, not used in debug block)               |
| LEDR[1]     | PIN_F19 | (mapped)                                        |
| LEDR[2]     | PIN_E19 | (mapped)                                        |
| LEDR[3]     | PIN_F21 | (mapped)                                        |
| LEDR[4]     | PIN_F18 | (mapped)                                        |
| LEDR[5]     | PIN_E18 | (mapped)                                        |
| LEDR[6]     | PIN_J19 | (mapped)                                        |
| LEDR[7]     | PIN_H19 | last received ASCII byte [7]                    |
| LEDR[8]     | PIN_J17 | blinks ~20ms on every received byte             |
| LEDR[9]     | PIN_G17 | blinks ~20ms when hex char received             |
| LEDR[10]    | PIN_J15 | hex_count[0] — char count bit 0                |
| LEDR[11]    | PIN_H16 | hex_count[1] — char count bit 1                |
| LEDR[12]    | PIN_J16 | hex_count[2] — char count bit 2                |
| LEDR[13]    | PIN_H17 | hex_count[3] — char count bit 3                |
| LEDR[14]    | PIN_F15 | hex_count[4] — char count bit 4                |
| LEDR[15]    | PIN_G15 | dbg_full — HIGH when 32 chars received          |
| LEDR[16]    | PIN_G16 | blinks ~20ms when Enter received                |
| LEDR[17]    | PIN_H15 | rx_sync2 raw line (idle=HIGH)                   |

NOTE: LEDR[7:0] in the debug_led_block maps led_byte[7:0] → LEDR[7:0].
So last byte ASCII appears on LEDR[7:0]. LEDR[6:0] pins above are
also mapped but those bits carry the lower ASCII byte bits.

---

## STEP 6: ARCHITECTURE FACTS FOR DOCS

### AES FSM States
```
IDLE        (3'd0) — waiting for start pulse
INIT        (3'd1) — load plaintext XOR rkey0 into state_reg
ROUND       (3'd2) — run rounds 1..9, round_cnt increments each clock
FINAL_ROUND (3'd3) — run round 10 (no MixColumns via sel_final=1)
DONE_ST     (3'd4) — assert done=1 for one cycle, return to IDLE
```

### Control signals from FSM to datapath
- `sel_load` — HIGH in INIT: forces state_reg ← plaintext XOR round_key
- `sel_final` — HIGH in FINAL_ROUND: bypasses MixColumns (uses shift_out not mix_out)
- `en` — HIGH in INIT/ROUND/FINAL_ROUND: enables state_reg to update
- `done` — HIGH for one cycle in DONE_ST

### Round key selection
- `aes_keyschedule` is fully combinational → produces all 11 round keys at once
- `current_rkey = rkey_flat[round_cnt * 128 +: 128]`
- round_cnt=0 → rkey0 (used in INIT), round_cnt=1..9 → rkey1..9 (ROUND),
  round_cnt set to 10 implicitly in FINAL_ROUND (check actual FSM logic)

### Key schedule
- Input: 128-bit key
- Output: rkey_flat[1407:0] = 11 × 128-bit round keys packed
- Implementation: genvar loop 1..10, each iteration:
  - RotWord: rotate last word left 8 bits
  - SubWord: 4× aes_sbox lookups
  - XOR with rcon[i] and previous key words
- Fully combinational, zero latency

### UART subsystem
- CLKS_PER_BIT = 50,000,000 / 9600 = 5208 clock cycles per bit
- START state: waits CLKS_PER_BIT/2 = 2604 cycles (sample at bit center)
- DATA state: samples at CLKS_PER_BIT-1 = 5207 cycles per bit
- 2-FF synchronizer: UART_RXD → rx_sync1 → rx_sync2 (prevents metastability)
- uart_rx_128 accumulates nibbles: shift_reg = {shift_reg[123:0], ascii_to_hex(rx_data)}
- On Enter (0x0D): data_out ← shift_reg, reset counters

### Display system
- 128-bit data → 4 × 32-bit segments via mux4x1_32bit
- btn → debounce → edge_detector → counter2_up (0→1→2→3→0)
- Each 32-bit segment → eight_sevenseg_32bit → 8 × hex_to_7seg
- Active-LOW encoding: 0 turns segment ON (DE2-115 hardware)
- Segment order: LEDG[1:0]=00 shows data[31:0] (rightmost hex chars)

---

## STEP 7: ENGINEERING PROBLEMS TO DOCUMENT

Include these in docs as "Design Challenges & Solutions":

### 1. Metastability (docs/03_uart_input.md)
**Problem:** UART_RXD changes asynchronously. If it changes near CLOCK_50
edge, the flip-flop output is undefined for unpredictable time → corrupted data.
**Solution:** 2-FF synchronizer (rx_sync1, rx_sync2). MTBF increases
exponentially with each additional synchronizer stage.
**Code:** `rx_sync1 <= UART_RXD; rx_sync2 <= rx_sync1;`

### 2. Mechanical switch bounce (docs/utils section)
**Problem:** Mechanical switches bounce for 1-20ms on transition.
Without debouncing, one press = hundreds of edge pulses.
**Solution:** 20-bit counter at 50MHz ≈ 20ms settle time.
Only updates btn_out when input has been stable for full 20ms.

### 3. Single-cycle pulse invisibility (docs/04_display_system.md)
**Problem:** dbg_is_hex fires for 1 clock cycle = 20ns at 50MHz.
Human eye minimum: ~10ms. Ratio: 10ms/20ns = 500,000x too fast.
**Solution:** Stretch register loaded with 20'hFFFFF (~20ms) on pulse,
decrements to zero. LED stays ON for ~20ms per event.

### 4. Hardwired reset (docs/03_uart_input.md)
**Problem:** Original design had .rst(1'b0) — UART FSM could never reset.
Any power-on glitch or noise could freeze FSM permanently.
**Solution:** .rst(reset) propagated through all levels.
Also added `data <= 0` to reset block and `default: state <= IDLE`.

### 5. Counter reset on done (docs/04_display_system.md)
**Problem:** After done fires, pressing clk_btn again increments counter past 11.
**Solution:** .rst(done | reset) — counter resets automatically when
encryption completes, ready for fresh count on next encryption.

### 6. Active-low 7-segment encoding (docs/04_display_system.md)
**Problem:** DE2-115 seven-segment displays are active-LOW.
Bit 0 = segment a ON, not OFF. Common mistake causes garbled display.
**Solution:** hex_to_7seg uses inverted encoding:
  0 → 7'b1000000 (segments bcdefg OFF, a ON)

### 7. key.txt path dependency (docs/08_results_and_analysis.md)
**Problem:** $readmemh("key.txt", mem) uses path relative to Quartus
project directory. Moving project breaks synthesis.
**Solution:** key.txt must be in the quartus/ working directory.
When restructuring, copy data/key.txt → quartus/key.txt.

### 8. STA negative slack explanation (docs/08_results_and_analysis.md)
**Observation:** STA shows negative slack on CLOCK_50 (-3.958ns setup).
**Explanation:** This is EXPECTED and NOT a problem. The AES combinational
path (SubBytes LUT chain → ShiftRows → MixColumns → AddRoundKey) is too
long for 50MHz auto-timing. But this design uses MANUAL BUTTON CLOCK —
the combinational path gets effectively unlimited time to settle between
human button presses (minimum ~100ms >> required ~5ns). The CLOCK_50
domain only drives UART and display, not the AES datapath.

---

## STEP 8: ALL 16 TEST VECTORS (VERIFIED)

For docs/07_test_vectors.md. All computed with PyCryptodome AES-128-ECB.

| SW[3:0] | Idx | Plaintext                        | Key                              | Expected Ciphertext              | NIST? |
|---------|-----|----------------------------------|----------------------------------|----------------------------------|-------|
| 0000    | 00  | 00112233445566778899AABBCCDDEEFF | 000102030405060708090A0B0C0D0E0F | 69C4E0D86A7B0430D8CDB78070B4C55A | ✓ NIST |
| 0001    | 01  | 00000000000000000000000000000000 | 00000000000000000000000000000000 | 66E94BD4EF8A2C3B884CFA59CA342B2E | ✓ NIST |
| 0010    | 02  | FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF | FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF | BCBF217CB280CF30B2517052193AB979 | ✓     |
| 0011    | 03  | 00000000000000000000000000000000 | FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF | A1F6258C877D5FCD8964484538BFC92C | ✓ NIST |
| 0100    | 04  | FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 00000000000000000000000000000000 | 3F5B8CC9EA855A0AFA7347D23E8D664E | ✓     |
| 0101    | 05  | 00112233445566778899AABBCCDDEEFF | 2B7E151628AED2A6ABF7158809CF4F3C | 8DF4E9AAC5C7573A27D8D055D6E4D64B | ✓     |
| 0110    | 06  | 000102030405060708090A0B0C0D0E0F | 000102030405060708090A0B0C0D0E0F | 0A940BB5416EF045F1C39458C653EA5A | ✓ NIST |
| 0111    | 07  | 6BC1BEE22E409F96E93D7E117393172A | 2B7E151628AED2A6ABF7158809CF4F3C | 3AD77BB40D7A3660A89ECAF32466EF97 | ✓ NIST |
| 1000    | 08  | AE2D8A571E03AC9C9EB76FAC45AF8E51 | 2B7E151628AED2A6ABF7158809CF4F3C | F5D3D58503B9699DE785895A96FDBAAF | ✓ NIST |
| 1001    | 09  | 30C81C46A35CE411E5FBC1191A0A52EF | 2B7E151628AED2A6ABF7158809CF4F3C | 43B1CD7F598ECE23881B00E3ED030688 | ✓ NIST |
| 1010    | 10  | F69F2445DF4F9B17AD2B417BE66C3710 | 2B7E151628AED2A6ABF7158809CF4F3C | 7B0C785E27E8AD3F8223207104725DD4 | ✓ NIST |
| 1011    | 11  | 00000000000000000000000000000000 | FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF | A1F6258C877D5FCD8964484538BFC92C | ✓     |
| 1100    | 12  | 11111111111111111111111111111111 | 00000000000000000000000000000000 | FFA3C7ED04710B98067DAE6815E2751F | ✓     |
| 1101    | 13  | 22222222222222222222222222222222 | FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF | C6BFD3CEEBCFD5406E5B3E0BAFB9D1B5 | ✓    |
| 1110    | 14  | 33333333333333333333333333333333 | 00000000000000000000000000000000 | 2E3A7007E0696FED74CDF0E5D2E4651D | ✓     |
| 1111    | 15  | 44444444444444444444444444444444 | FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF | D6F13021DF12A669813A50D15D92A629 | ✓     |

Online verification tool: https://www.cryptool.org/en/cto/aes-step-by-step
Quick check tool: https://aesencryption.net
Always use ECB mode, 128-bit key, no padding.

---

## STEP 9: DOCS CONTENT OUTLINE

Generate each doc file in this order. Content guide below.

### docs/01_architecture.md
- System overview paragraph (what it does end to end)
- Module hierarchy tree (21 modules, 5 subsystems)
- Data flow: UART RX → uart_rx → uart_rx_128 → plaintext[127:0]
  → aes_core → ciphertext[127:0] → top_128bit_display → HEX7..HEX0
- Clock domains table:
  - CLOCK_50 (50MHz): UART, display, debug LEDs, synchronizer, key ROM
  - clk (debounced SW17): AES FSM, AES datapath, clk_counter
- Design decisions section:
  - Why manual clock: allows observing FSM state per round
  - Why ROM for keys: simplifies demo, SW selects test vector
  - Why 2-FF synchronizer: metastability prevention
  - Why iterative not pipelined: area efficient, visible round-by-round

### docs/02_aes_core.md
- AES-128 algorithm summary (NIST FIPS 197 reference)
- Iterative architecture diagram description
- FSM explained: 5 states, what each does, which control signals
- Datapath explained: state_reg, the sel_final MUX, sel_load MUX
- Each sub-module: subbytes (16x parallel sbox), shiftrows (wire reorder),
  mixcolumns (xtime GF2^8), keyschedule (genvar loop, 44 words)
- xtime function explained with example: 0x57 → 0xAE
- Why FINAL_ROUND skips MixColumns (NIST spec requirement)
- Key schedule: RotWord, SubWord, Rcon table

### docs/03_uart_input.md
- UART protocol: 9600 baud 8N1, frame format diagram
- CLKS_PER_BIT calculation: 50,000,000 / 9600 = 5208
- uart_rx FSM: 4 states, timing diagram
- 2-FF synchronizer: what metastability is, why 2 FFs fix it
- uart_rx_128: ASCII hex filtering, shift accumulation, Enter latch
- ascii_to_hex function: '0'-'9', 'A'-'F', 'a'-'f' ranges
- Reset chain: reset → uart_rx_128 → uart_rx
- What happens on wrong input (non-hex chars ignored)

### docs/04_display_system.md
- 128-bit → 4×32-bit segment selection
- Scrolling mechanism: btn → debounce → edge_detector → counter2_up
- Segment mapping table: LEDG[1:0] value → which bits displayed
- Active-low 7-seg encoding table (all 16 hex digits)
- Debug LED block: LEDR[17:0] reference table
- Pulse stretching math: 20'hFFFFF cycles × 20ns = 20.97ms
- LEDG mapping: status[1:0] + clk_count[4:0] + done

### docs/05_pin_assignments.md
- Full pin table (copy from STEP 6 above)
- Board diagram description (where to find each SW/LED/connector)
- Note on key.txt location requirement
- QSF snippet to copy-paste

### docs/06_how_to_use.md
- Prerequisites: Quartus 22.1, DE2-115, USB-UART cable
- Programming the FPGA: where .sof file is, USB Blaster steps
- PuTTY settings: Serial, COM port, 9600, 8, None, 1, None
- Step by step with expected observations at each step:
  1. Power on → LEDR[17] should be HIGH (idle)
  2. Open terminal → type 32 hex chars → watch LEDR[14:10] count
  3. LEDR[15] HIGH = ready → press Enter → LEDR[16] blinks
  4. Set SW[3:0] for key index
  5. debug_sel=0 → verify plaintext on display (scroll with KEY0)
  6. Flip SW5 (start) HIGH then LOW
  7. Press SW17 (clk_btn) 11 times → watch LEDG[6:2] count 00001→01011
  8. LEDG[7] HIGH = done → LEDG[6:2] resets to 00000
  9. debug_sel=1 → scroll ciphertext → compare to table
- Reset procedure: SW10 HIGH briefly → clears everything
- Common mistakes section

### docs/07_test_vectors.md
- Explanation of SW[3:0] addressing
- Full table (copy from STEP 8 above)
- How to read display: seg00=data[31:0], seg01=[63:32], seg10=[95:64], seg11=[127:96]
- How to assemble: seg11+seg10+seg01+seg00 = full 128-bit ciphertext
- Online verification links
- Note about original expected.txt errors (rows 2,4,5,12,13,14,15 corrected)

### docs/08_results_and_analysis.md
- Resource utilization table (from STEP 6)
- Timing analysis: STA negative slack explanation (see STEP 7 item 8)
- What was verified on hardware (list test vectors verified on board)
- Known limitations:
  - No UART TX (cannot echo ciphertext back to terminal)
  - Manual clock only — not running at 50MHz
  - No AES decryption
  - Key ROM is static (no runtime key loading)
  - STA negative slack (expected, not a bug)
- Future work:
  - UART TX to echo ciphertext
  - Pipelined architecture (already designed separately)
  - AES-256 extension
  - CBC/CTR mode wrapper
  - LCD display instead of 7-seg scrolling

---

## STEP 10: README.md OUTLINE

The README is the first thing anyone sees. Write it last, reference all docs.

Sections:
1. Title + one-line description + badges
   - Badge ideas: Verified on FPGA | NIST AES-128 | Cyclone IV E | 9600 baud | Quartus 22.1
2. Demo GIF/video thumbnail (placeholder — user will add)
3. Quick start (3 steps: clone, program .sof, open terminal)
4. System block diagram (ASCII or image)
5. Features list
6. Hardware requirements
7. Project structure (the folder tree)
8. Documentation links (link to all 8 docs)
9. Test vectors table (abbreviated — full in doc 07)
10. Resource utilization summary
11. Team / contributors (link to CONTRIBUTORS.md)
12. References (NIST FIPS 197, DE2-115 manual)
13. License

---

## STEP 11: CONTRIBUTORS.md

| Name              | ID         | Module                    | Contribution                          |
|-------------------|------------|---------------------------|---------------------------------------|
| Kaarmukilan       | 23BEC0137  | top.v, debug, I/O         | System integration, UART I/O, display |
| Monish Kumar      | 23BEC0009  | aes_mixcolumns.v          | GF(2^8) MixColumns implementation    |
| Sanjay Karthikeyan| 23BEC0503  | aes_keyschedule.v, FSM    | Key schedule, FSM, system assembly    |
| Jonish Jack Kenned| 23BEC0475  | aes_subbytes.v, aes_sbox.v| S-Box ROM, SubBytes                   |
| Raajaprasanna M   | 23BEC0283  | aes_shiftrows.v           | ShiftRows byte reordering             |

---

## EXECUTION ORDER FOR CLAUDE CODE

1. Create all directories
2. Create .gitignore
3. Split top.v into individual module files (read top.v, extract each module)
4. Split aes_core.v into individual module files
5. Move key_rom128.v to src/aes/
6. Create src/top.v with only the top module
7. Update quartus/top.qsf with new file paths
8. Create data/expected.txt with corrected values
9. Create docs/ folder and all 8 .md files
10. Create README.md
11. Create CONTRIBUTORS.md
12. Verify: count .v files in src/ — should be 21 total

---

## IMPORTANT NOTES FOR CLAUDE CODE

- Do NOT change any Verilog code. Extract verbatim.
- The module splitting is purely organizational — zero logic changes.
- key.txt MUST be copied to quartus/ folder (Quartus reads it from project dir)
- When writing docs, use the architecture facts in STEP 6 — do not guess
- The design is NON-PIPELINED (FSM+datapath), NOT the 11-stage pipeline
- done fires for ONE cycle in DONE_ST state, then FSM returns to IDLE
- The clk signal (AES clock) comes from debounce of clk_btn (SW17)
- CLOCK_50 is used for UART, display, and debug only
- Images in docs/images/ are placeholders — user will add RTL screenshots,
  simulation waveforms, and board photos manually

---

*Generated from Claude.ai conversation — May/June 2026*
*Project: High Performance AES-128 Encryption Accelerator on DE2-115 FPGA*
*Course: FPGA System Design, VIT Vellore*
