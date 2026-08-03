# 04 — Display & Debug System

## 128-bit → 4 × 32-bit Segments

The eight 7-segment displays show 8 hex digits = 32 bits at a time, so the 128-bit value is split into four segments selected by `mux4x1_32bit`:

| LEDG[1:0] (status_led) | Displayed bits | Hex chars (of 32) |
|------------------------|----------------|-------------------|
| 00 | data[31:0] | rightmost 8 (chars 25–32) |
| 01 | data[63:32] | chars 17–24 |
| 10 | data[95:64] | chars 9–16 |
| 11 | data[127:96] | leftmost 8 (chars 1–8) |

Full value = segment 11 + segment 10 + segment 01 + segment 00 concatenated.

## Scrolling Mechanism

```
KEY0 (btn) → debounce → edge_detector → counter2_up (0→1→2→3→0) → mux4x1_32bit sel
```

Each clean press advances the segment counter by one; the current segment index is shown on LEDG[1:0]. The counter resets with `reset`.

## Switch Debouncing

**Problem:** mechanical switches bounce for 1–20 ms per transition. Without debouncing, one press = hundreds of edge pulses.

**Solution:** `debounce` uses a 20-bit counter at 50 MHz ≈ 20 ms settle time. `btn_out` only updates after the input has been stable for the full 20 ms.

## Active-Low 7-Segment Encoding

**Problem:** the DE2-115 seven-segment displays are **active-LOW** — bit = 0 turns a segment ON. Using active-high encoding produces a garbled display.

`hex_to_7seg` encoding table (seg = {g,f,e,d,c,b,a}):

| Hex | seg[6:0] | | Hex | seg[6:0] |
|-----|----------|-|-----|----------|
| 0 | `1000000` | | 8 | `0000000` |
| 1 | `1111001` | | 9 | `0010000` |
| 2 | `0100100` | | A | `0001000` |
| 3 | `0110000` | | B | `0000011` |
| 4 | `0011001` | | C | `1000110` |
| 5 | `0010010` | | D | `0100001` |
| 6 | `0000010` | | E | `0000110` |
| 7 | `1111000` | | F | `0001110` |

## Debug LED Block (LEDR[17:0])

| LED | Function |
|-----|----------|
| LEDR[7:0] | Last received ASCII byte (holds until next byte) |
| LEDR[8] | Blinks ~20 ms on every received byte |
| LEDR[9] | Blinks ~20 ms when a valid hex char is received |
| LEDR[14:10] | `hex_count[4:0]` — chars received (0–31 in binary) |
| LEDR[15] | `dbg_full` — HIGH when 32 chars accumulated (ready) |
| LEDR[16] | Blinks ~20 ms when Enter received |
| LEDR[17] | `rx_sync2` raw UART line (idle = HIGH) |

## Pulse Stretching

**Problem:** flags like `dbg_is_hex` fire for exactly 1 clock cycle = 20 ns at 50 MHz. The human eye needs ~10 ms — a factor of 500,000× too fast to see.

**Solution:** on each pulse a stretch register is loaded with `20'hFFFFF` and decremented to zero; the LED stays on while non-zero:

```
2^20 cycles × 20 ns = 1,048,575 × 20 ns ≈ 20.97 ms per event
```

## LEDG Mapping

| LED | Function |
|-----|----------|
| LEDG[1:0] | `status_led` — current display segment index |
| LEDG[6:2] | `clk_count[4:0]` — number of AES clock presses |
| LEDG[7] | `done` |

## Clock Counter Reset

**Problem:** after `done` fires, pressing SW17 again would keep incrementing the counter past 11.

**Solution:** `clk_counter` is instantiated with `.rst(done | reset)` — the counter clears automatically when encryption completes, ready for a fresh count on the next run.
