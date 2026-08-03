# 03 — UART Plaintext Input

## Protocol

9600 baud, 8 data bits, no parity, 1 stop bit (8N1). Frame format:

```
idle(1) ──┐start(0)│ b0 │ b1 │ b2 │ b3 │ b4 │ b5 │ b6 │ b7 │stop(1)┌── idle(1)
          └────────┴────┴────┴────┴────┴────┴────┴────┴────┴───────┘
           LSB first
```

## Bit Timing

```
CLKS_PER_BIT = CLK_FREQ / BAUD = 50,000,000 / 9600 = 5208 clock cycles per bit
```

- **START state:** waits `CLKS_PER_BIT/2 = 2604` cycles — this lands the sampling point in the **center** of each bit, maximizing tolerance to baud-rate mismatch.
- **DATA state:** samples every `CLKS_PER_BIT - 1 = 5207` cycles, LSB first, 8 bits.
- **STOP state:** waits one more bit time, then asserts `valid` for one cycle with the byte on `data`.

`uart_rx` is a 4-state FSM: `IDLE → START → DATA → STOP → IDLE`.

## Metastability & the 2-FF Synchronizer

**Problem:** `UART_RXD` changes asynchronously to CLOCK_50. If the line toggles right at a clock edge, the capturing flip-flop can go metastable — its output is undefined for an unpredictable time, potentially corrupting the FSM.

**Solution:** two flip-flops in series in `top.v`:

```verilog
rx_sync1 <= UART_RXD;
rx_sync2 <= rx_sync1;
```

Only `rx_sync2` is ever used by logic. MTBF (mean time between failures) increases exponentially with each synchronizer stage, so two stages make failures practically impossible at 50 MHz/9600 baud.

## 128-bit Accumulation (uart_rx_128)

- Each received byte is classified by `is_hex()` — `'0'-'9'`, `'A'-'F'`, `'a'-'f'`.
- Valid hex chars are converted by `ascii_to_hex()` and shifted in:

  ```verilog
  shift_reg <= {shift_reg[123:0], ascii_to_hex(rx_data)};
  ```

  so the **first typed character becomes the most-significant nibble**.
- `hex_count` counts 0→32; once 32 chars are in, `dbg_full` goes HIGH (LEDR[15]) and further hex chars are ignored.
- **On Enter (0x0D):** `data_out ← shift_reg`, counters reset, `dbg_enter` pulses (LEDR[16] blinks). Only at this moment does the plaintext output update.
- **Non-hex characters are simply ignored** — typing a wrong character does not corrupt the buffer; backspace is *not* supported, use reset (SW10) and retype.

## Reset Chain

**Problem (original design):** `uart_rx` was instantiated with `.rst(1'b0)` — the UART FSM could never be reset. A power-on glitch or line noise could freeze the FSM permanently.

**Fix:** `reset` (SW10) is propagated through all levels: `top → uart_rx_128 → uart_rx`. Additionally `data <= 0` was added to the reset block and a `default: state <= IDLE` arm added to the case statement, so an illegal state always recovers.
