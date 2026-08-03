
// top.v — Full integrated AES system with UART plaintext input
//
// Plaintext : via UART (32 hex chars + Enter at 9600 8N1)
// Key       : via key_rom128, selected by SW[3:0] switches
// Encrypt   : pulse start pin
// Display   : btn scrolls HEX7..HEX0; debug_sel picks plaintext vs ciphertext
//
// DEBUG LEDs (LEDR[17:0]):
//   LEDR[7:0]   — last received ASCII byte, holds until next byte
//   LEDR[8]     — blinks ~20ms on every received byte
//   LEDR[9]     — blinks ~20ms when a valid hex char received
//   LEDR[14:10] — hex_count in binary (0..31)
//   LEDR[15]    — high when 32 hex chars accumulated (ready)
//   LEDR[16]    — blinks ~20ms when Enter received
//   LEDR[17]    — rx_sync2 line state (idle=1, receiving=0)
//
// LEDG mapping:
//   LEDG[1:0]  — status_led (display segment index)
//   LEDG[6:2]  — clk_counter count (how many AES clocks pressed)
//   LEDG[7]    — done

module top (
    input  wire        CLOCK_50,
    input  wire        UART_RXD,
    input  wire        clk_btn,//17
    input  wire        reset,//10
    input  wire        btn,//key0
    input  wire        debug_sel,//7
    input  wire [3:0]  SW,
    input  wire        start,//5

    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    output wire [6:0]  HEX6,
    output wire [6:0]  HEX7,

    //output wire        done,

    output wire [17:0] LEDR,
    output wire [7:0]  LEDG
);

    // -------------------------------------------------------------------------
    // Debounced AES clock
    // -------------------------------------------------------------------------
    wire clk;
    debounce db_clk (
        .clk    (CLOCK_50),
        .btn_in (clk_btn),
        .btn_out(clk)
    );

    // -------------------------------------------------------------------------
    // 2-FF Synchronizer — UART_RXD never used directly in any logic
    // -------------------------------------------------------------------------
    reg rx_sync1, rx_sync2;

    always @(posedge CLOCK_50) begin
        rx_sync1 <= UART_RXD;
        rx_sync2 <= rx_sync1;
    end

    // -------------------------------------------------------------------------
    // PLAINTEXT — UART
    // -------------------------------------------------------------------------
    wire [127:0] plaintext;
    wire [7:0]   dbg_rx_data;
    wire         dbg_rx_valid;
    wire         dbg_is_hex;
    wire [5:0]   dbg_hex_count;
    wire         dbg_enter;
    wire         dbg_full;

    uart_rx_128 #(
        .CLK_FREQ(50000000),
        .BAUD    (9600)
    ) uart_plain_inst (
        .clk          (CLOCK_50),
        .rst          (reset),
        .rx           (rx_sync2),
        .data_out     (plaintext),
        .dbg_rx_data  (dbg_rx_data),
        .dbg_rx_valid (dbg_rx_valid),
        .dbg_is_hex   (dbg_is_hex),
        .dbg_hex_count(dbg_hex_count),
        .dbg_enter    (dbg_enter),
        .dbg_full     (dbg_full)
    );

    // -------------------------------------------------------------------------
    // Debug LED Block
    // -------------------------------------------------------------------------
    debug_led_block dbg_inst (
        .clk          (CLOCK_50),
        .dbg_rx_data  (dbg_rx_data),
        .dbg_rx_valid (dbg_rx_valid),
        .dbg_is_hex   (dbg_is_hex),
        .dbg_hex_count(dbg_hex_count),
        .dbg_enter    (dbg_enter),
        .dbg_full     (dbg_full),
        .uart_rx_raw  (rx_sync2),
        .LEDR         (LEDR)
    );

    // -------------------------------------------------------------------------
    // KEY — ROM
    // -------------------------------------------------------------------------
    wire [127:0] key;

    key_rom128 key_rom (
        .clk    (CLOCK_50),
        .addr   (SW),
        .key_out(key)
    );

    // -------------------------------------------------------------------------
    // AES CORE
    // -------------------------------------------------------------------------
    wire [127:0] ciphertext;

    aes_core aes_inst (
        .clk       (clk),
        .plaintext (plaintext),
        .start     (start),
        .key       (key),
        .ciphertext(ciphertext),
        .done      (done)
    );

    // -------------------------------------------------------------------------
    // Clock Counter — counts AES clk pulses, resets on done
    // -------------------------------------------------------------------------
    wire [4:0] clk_count;

    clk_counter clk_cnt_inst (
        .clk  (clk),
        .rst  (done|reset),
        .count(clk_count)
    );

    // -------------------------------------------------------------------------
    // Debug MUX
    // -------------------------------------------------------------------------
    wire [127:0] selected_data;
    assign selected_data = (debug_sel == 1'b0) ? plaintext : ciphertext;

    // -------------------------------------------------------------------------
    // 7-seg Display
    // -------------------------------------------------------------------------
wire [1:0]status_led;
    top_128bit_display display_inst (
        .clk       (CLOCK_50),
        .reset     (reset),
        .btn       (btn),
        .data      (selected_data),
        .seg0      (HEX0),
        .seg1      (HEX1),
        .seg2      (HEX2),
        .seg3      (HEX3),
        .seg4      (HEX4),
        .seg5      (HEX5),
        .seg6      (HEX6),
        .seg7      (HEX7),
        .status_led(status_led)
    );


 // -------------------------------------------------------------------------
    // LEDG wiring
    // -------------------------------------------------------------------------
    assign LEDG[1:0] = status_led;
    assign LEDG[6:2] = clk_count;
    assign LEDG[7]   = done;

endmodule
