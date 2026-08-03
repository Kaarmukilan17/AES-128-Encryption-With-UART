# 05 — Pin Assignments (DE2-115)

## Control Inputs (named ports — NOT the SW bus)

| Signal | Comment in code | Quartus Pin | DE2-115 Physical |
|-----------|----------------|-------------|------------------|
| CLOCK_50 | system clock | PIN_Y2 | CLOCK_50 |
| UART_RXD | serial input | PIN_G12 | UART_RXD |
| clk_btn | //17 | PIN_Y23 | SW17 |
| reset | //10 | PIN_AC24 | SW10 |
| btn | //key0 | PIN_M23 | KEY0 |
| debug_sel | //7 | PIN_AB26 | SW7 |
| start | //5 | PIN_AC26 | SW5 |

> **Note:** `clk_btn`, `reset`, `debug_sel`, `start` are mapped to *individual* SW pins (SW17, SW10, SW7, SW5), not through the SW[3:0] bus. The SW[3:0] bus is used ONLY for the key ROM address.

## Key ROM Address

| Signal | Pin | Physical |
|--------|----------|----------|
| SW[0] | PIN_AB28 | SW0 |
| SW[1] | PIN_AC28 | SW1 |
| SW[2] | PIN_AC27 | SW2 |
| SW[3] | PIN_AD27 | SW3 |

SW[3:0] = 0000 → key index 0, SW[3:0] = 0001 → key index 1, … up to 1111 → key index 15.

## LEDG Output

| Signal | Pin | Function |
|---------|---------|----------------------------------|
| LEDG[0] | PIN_E21 | status_led[0] — display segment |
| LEDG[1] | PIN_E22 | status_led[1] — display segment |
| LEDG[2] | PIN_E25 | clk_count[0] |
| LEDG[3] | PIN_E24 | clk_count[1] |
| LEDG[4] | PIN_H21 | clk_count[2] |
| LEDG[5] | PIN_G20 | clk_count[3] |
| LEDG[6] | PIN_G22 | clk_count[4] |
| LEDG[7] | PIN_G21 | done signal |

## LEDR Debug Output

| Signal | Pin | Function |
|----------|---------|--------------------------------------------------|
| LEDR[0] | PIN_G19 | (mapped, not used in debug block) |
| LEDR[1] | PIN_F19 | (mapped) |
| LEDR[2] | PIN_E19 | (mapped) |
| LEDR[3] | PIN_F21 | (mapped) |
| LEDR[4] | PIN_F18 | (mapped) |
| LEDR[5] | PIN_E18 | (mapped) |
| LEDR[6] | PIN_J19 | (mapped) |
| LEDR[7] | PIN_H19 | last received ASCII byte [7] |
| LEDR[8] | PIN_J17 | blinks ~20ms on every received byte |
| LEDR[9] | PIN_G17 | blinks ~20ms when hex char received |
| LEDR[10] | PIN_J15 | hex_count[0] — char count bit 0 |
| LEDR[11] | PIN_H16 | hex_count[1] — char count bit 1 |
| LEDR[12] | PIN_J16 | hex_count[2] — char count bit 2 |
| LEDR[13] | PIN_H17 | hex_count[3] — char count bit 3 |
| LEDR[14] | PIN_F15 | hex_count[4] — char count bit 4 |
| LEDR[15] | PIN_G15 | dbg_full — HIGH when 32 chars received |
| LEDR[16] | PIN_G16 | blinks ~20ms when Enter received |
| LEDR[17] | PIN_H15 | rx_sync2 raw line (idle=HIGH) |

> **Note:** LEDR[7:0] in `debug_led_block` maps `led_byte[7:0]` → LEDR[7:0], so the last received ASCII byte appears on LEDR[7:0]. The LEDR[6:0] pins above are also mapped, carrying the lower ASCII byte bits.

## key.txt Location Requirement

`key_rom128` loads keys with `$readmemh("key.txt", mem)` — the path is resolved relative to the **Quartus project working directory**. `key.txt` must therefore sit next to `top.qsf` in `quartus/` (a copy is kept there; the master copy lives in `data/`).

## QSF Snippet (source files)

```tcl
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

## Board Orientation

On the DE2-115: the 18 red LEDs (LEDR) and 18 slide switches (SW17..SW0) run along the bottom edge, red LEDs directly above their switches. The 9 green LEDs (LEDG) and 4 push-buttons (KEY3..KEY0) are on the bottom-right. The eight 7-segment displays (HEX7..HEX0) are above the switches. The RS-232 (UART) connector is on the top edge; the USB-Blaster connector is top-left.
