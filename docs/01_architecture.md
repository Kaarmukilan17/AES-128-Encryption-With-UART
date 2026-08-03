# 01 — System Architecture

## Overview

This project is a complete AES-128 encryption accelerator on the Altera DE2-115 FPGA (Cyclone IV E, EP4CE115F29C7). The plaintext arrives over UART as 32 hex characters (terminated by Enter) at 9600 baud 8N1. The key is selected from a 16-entry on-chip ROM using switches SW[3:0]. Encryption runs on a **manual clock**: each press of SW17 advances the AES FSM by exactly one round, so 11 presses complete a full AES-128 encryption. The result is scrolled across the eight 7-segment displays, 32 bits at a time, using KEY0.

**Architecture: iterative FSM-based (NOT pipelined).** A single shared combinational round datapath is reused 11 times under FSM control, instead of instantiating 11 pipeline stages.

## Module Hierarchy (21 modules, 5 subsystems)

```
top
├── debounce (db_clk)                 — SW17 → clean AES clock
├── uart_rx_128 (uart_plain_inst)     — UART subsystem
│   └── uart_rx                       — byte-level UART FSM
├── debug_led_block                   — LEDR[17:0] debug outputs
├── key_rom128                        — 16 × 128-bit key ROM ($readmemh)
├── aes_core                          — AES subsystem
│   ├── aes_keyschedule               — combinational key expansion
│   │   └── aes_sbox ×40              — SubWord lookups
│   ├── aes_fsm                       — 5-state round sequencer
│   └── aes_datapath                  — one shared round
│       ├── aes_subbytes
│       │   └── aes_sbox ×16
│       ├── aes_shiftrows
│       └── aes_mixcolumns
├── clk_counter                       — counts AES clock presses (LEDG[6:2])
└── top_128bit_display                — display subsystem
    ├── debounce
    ├── edge_detector
    ├── counter2_up
    ├── mux4x1_32bit
    └── eight_sevenseg_32bit
        └── hex_to_7seg ×8
```

## Data Flow

```
UART_RXD → 2-FF synchronizer → uart_rx → uart_rx_128 → plaintext[127:0]
                                                            │
SW[3:0] → key_rom128 → key[127:0] ──────────────────────► aes_core
                                                            │
                                            ciphertext[127:0]
                                                            │
              debug_sel mux (plaintext / ciphertext) → top_128bit_display → HEX7..HEX0
```

## Clock Domains

| Clock | Source | Drives |
|-------|--------|--------|
| CLOCK_50 (50 MHz) | On-board oscillator (PIN_Y2) | UART receiver, display subsystem, debug LEDs, 2-FF synchronizer, key ROM |
| clk (manual) | SW17 → debounce | AES FSM, AES datapath, clk_counter |

## Design Decisions

- **Why a manual clock:** each button press advances one round, so the FSM state and intermediate values can be observed round by round on hardware — ideal for demonstration and debugging.
- **Why a ROM for keys:** simplifies the demo. SW[3:0] instantly selects one of 16 pre-loaded test-vector keys with no extra input path.
- **Why a 2-FF synchronizer:** UART_RXD is asynchronous to CLOCK_50; two flip-flops in series prevent metastability from propagating into the UART FSM (see [03_uart_input.md](03_uart_input.md)).
- **Why iterative instead of pipelined:** one shared round datapath is area-efficient (6,485 LEs — 6% of the chip) and makes the round-by-round operation visible. A pipelined variant was designed separately.
