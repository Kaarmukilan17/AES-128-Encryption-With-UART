# 02 — AES Core

## AES-128 in Brief

AES-128 (NIST FIPS 197) encrypts a 128-bit block with a 128-bit key in 10 rounds. Each round applies four transformations to the 16-byte state: **SubBytes** (non-linear S-Box substitution), **ShiftRows** (cyclic row rotation), **MixColumns** (GF(2⁸) column mixing), and **AddRoundKey** (XOR with the round key). Before round 1 there is an initial AddRoundKey with the original key, and the final round (round 10) **skips MixColumns** — this is required by the FIPS 197 specification.

## Iterative Architecture

`aes_core` is a thin wrapper that connects three blocks:

- `aes_keyschedule` — fully combinational; expands the key into all 11 round keys at once (`rkey_flat[1407:0]`).
- `aes_fsm` — sequences the rounds and drives the datapath control signals.
- `aes_datapath` — **one** combinational round (SubBytes → ShiftRows → MixColumns → AddRoundKey) plus the 128-bit `state_reg`. The same hardware is reused for all 11 clock cycles.

The current round key is selected from the flat bus:

```verilog
assign current_rkey = rkey_flat[round_cnt*128 +: 128];
```

## FSM (aes_fsm)

Five states:

| State | Encoding | Action |
|-------|----------|--------|
| `IDLE` | 3'd0 | Wait for `start` pulse |
| `INIT` | 3'd1 | Load `state_reg ← plaintext XOR rkey0` |
| `ROUND` | 3'd2 | Rounds 1–9; `round_cnt` increments each clock |
| `FINAL_ROUND` | 3'd3 | Round 10, MixColumns bypassed (`sel_final=1`) |
| `DONE_ST` | 3'd4 | Assert `done=1` for one cycle, return to `IDLE` |

Control signals to the datapath:

- `sel_load` — HIGH in `INIT`: forces `state_reg ← plaintext ^ round_key`
- `sel_final` — HIGH in `FINAL_ROUND`: selects `shift_out` instead of `mix_out` (bypasses MixColumns)
- `en` — HIGH in `INIT`/`ROUND`/`FINAL_ROUND`: enables `state_reg` to update
- `done` — HIGH for exactly one cycle in `DONE_ST`

`round_cnt` is set to 1 in `INIT`, increments through `ROUND` (1→9), and the FSM moves to `FINAL_ROUND` when `round_cnt == 9`. With the manual clock, this means: press 1 = INIT, presses 2–10 = rounds 1–9, press 11 = final round, and `done` appears on LEDG[7].

## Datapath (aes_datapath)

```
state_reg → aes_subbytes → aes_shiftrows → aes_mixcolumns
                                 │               │
                                 └── sel_final ──┴─→ mux_mix ─ XOR round_key → addrk_out
state_reg ← (sel_load ? plaintext^round_key : addrk_out)   when en
```

## Sub-modules

- **aes_subbytes** — 16 parallel `aes_sbox` instances via a generate loop; substitutes all 16 state bytes in one combinational pass.
- **aes_sbox** — 256-entry ROM (`reg [7:0] sbox [0:255]` with an `initial` block), synthesized as a LUT.
- **aes_shiftrows** — pure wire reassignment: row *r* rotates left by *r* bytes (`sr[r][c] = s[r][(c+r) % 4]`). Zero logic cost.
- **aes_mixcolumns** — each 32-bit column is mixed in GF(2⁸) using the `xtime` function (multiply-by-2):

  ```verilog
  xtime = b[7] ? ({b[6:0],1'b0} ^ 8'h1b) : {b[6:0],1'b0};
  ```

  Example: `xtime(0x57)` → `0x57` has bit 7 = 0, so result is `0xAE` (simple left shift). If bit 7 were set, the shifted value is XORed with the reduction polynomial `0x1B`.

## Key Schedule (aes_keyschedule)

- Input: 128-bit key; output: `rkey_flat[1407:0]` = 11 × 128-bit round keys packed.
- Words `w[0..3]` are the original key. A genvar loop for i = 1..10 computes each subsequent group of 4 words:
  - **RotWord** — rotate the previous word left by 8 bits
  - **SubWord** — 4 parallel `aes_sbox` lookups
  - XOR with `rcon[i]` (round constants 01,02,04,08,10,20,40,80,1B,36) and the word 4 positions back
- Fully combinational — all 44 words (11 round keys) are available with zero latency, which is why the FSM can index any round key directly with `round_cnt`.
