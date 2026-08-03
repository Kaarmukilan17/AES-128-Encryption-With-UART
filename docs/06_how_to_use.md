# 06 — How to Use

## Prerequisites

- Intel Quartus Prime 22.1 std (with Cyclone IV E device support)
- Terasic DE2-115 board (EP4CE115F29C7)
- USB cable for the USB-Blaster + RS-232/USB-UART cable for the serial input
- A serial terminal (PuTTY recommended)

## Programming the FPGA

1. Open Quartus → Tools → Programmer (or run `quartus_pgm`).
2. Hardware Setup → select **USB-Blaster**.
3. Mode: **JTAG**. Add File → `quartus/output_files/top.sof` (compile the project first if the .sof is missing).
4. Check *Program/Configure*, press **Start**, wait for 100%.

## Terminal Settings (PuTTY)

| Setting | Value |
|---------|-------|
| Connection type | Serial |
| Serial line | your COM port (check Device Manager) |
| Speed (baud) | 9600 |
| Data bits | 8 |
| Parity | None |
| Stop bits | 1 |
| Flow control | None |

## Step-by-Step Operation

1. **Power on / program** → LEDR[17] should be HIGH (UART line idle).
2. **Open the terminal** and type the 32 hex characters of the plaintext → watch LEDR[14:10] count up in binary, LEDR[8]/LEDR[9] blink per character.
3. **LEDR[15] HIGH** = 32 chars ready → press **Enter** → LEDR[16] blinks (plaintext latched).
4. **Set SW[3:0]** to the key index (see [07_test_vectors.md](07_test_vectors.md)).
5. **debug_sel (SW7) = 0** → verify the plaintext on the display, scrolling segments with **KEY0** (segment index on LEDG[1:0]).
6. **Flip SW5 (start) HIGH**, then back LOW.
7. **Press SW17 (clk_btn) 11 times** — each press is one AES round. Watch LEDG[6:2] count 00001 → 01011.
8. **LEDG[7] HIGH = done** — LEDG[6:2] resets to 00000 automatically.
9. **debug_sel (SW7) = 1** → scroll through the ciphertext with KEY0 and compare against the test-vector table.

## Reset Procedure

Flip **SW10 HIGH briefly, then LOW** — clears the UART buffer, plaintext latch, display counter and clock counter.

## Common Mistakes

- **Forgetting Enter** — the plaintext is only latched on Enter (0x0D). LEDR[15] HIGH just means the buffer is full.
- **Leaving start (SW5) HIGH** — `start` is level-sampled in IDLE; leave it HIGH and the core immediately restarts encryption after done. Pulse it: up, then down.
- **Counting presses wrong** — 11 presses total (1 init + 9 rounds + 1 final). LEDG[6:2] shows the count; wait for LEDG[7].
- **Wrong segment order when reading the display** — segment 00 is data[31:0], the *rightmost* 8 hex chars. See [07_test_vectors.md](07_test_vectors.md).
- **Typing lowercase hex** — actually fine; `a-f` and `A-F` are both accepted.
- **Wrong COM port / baud** — if LEDR[8] never blinks while typing, the board isn't receiving; check port and 9600 8N1.
- **key.txt missing next to the Quartus project** — synthesis embeds the ROM contents from `quartus/key.txt`; keep it there when recompiling.
