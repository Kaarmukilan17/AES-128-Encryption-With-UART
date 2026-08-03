// -----------------------------------------------------------------------------
// DEBUG_LED_BLOCK
// All single-cycle pulses stretched ~20ms for human visibility
// -----------------------------------------------------------------------------
module debug_led_block (
    input  wire        clk,
    input  wire [7:0]  dbg_rx_data,
    input  wire        dbg_rx_valid,
    input  wire        dbg_is_hex,
    input  wire [5:0]  dbg_hex_count,
    input  wire        dbg_enter,
    input  wire        dbg_full,
    input  wire        uart_rx_raw,
    output wire [17:0] LEDR
);

    reg [7:0]  led_byte      = 8'd0;
    reg [19:0] valid_stretch = 20'd0;
    reg [19:0] hex_stretch   = 20'd0;
    reg [19:0] enter_stretch = 20'd0;

    always @(posedge clk) begin

        if (dbg_rx_valid)
            led_byte <= dbg_rx_data;

        if (dbg_rx_valid)
            valid_stretch <= 20'hFFFFF;
        else if (valid_stretch != 0)
            valid_stretch <= valid_stretch - 1;

        if (dbg_is_hex)
            hex_stretch <= 20'hFFFFF;
        else if (hex_stretch != 0)
            hex_stretch <= hex_stretch - 1;

        if (dbg_enter)
            enter_stretch <= 20'hFFFFF;
        else if (enter_stretch != 0)
            enter_stretch <= enter_stretch - 1;

    end

    assign LEDR[7:0]   = led_byte;
    assign LEDR[8]     = (valid_stretch != 0);
    assign LEDR[9]     = (hex_stretch   != 0);
    assign LEDR[14:10] = dbg_hex_count[4:0];
    assign LEDR[15]    = dbg_full;
    assign LEDR[16]    = (enter_stretch != 0);
    assign LEDR[17]    = uart_rx_raw;

endmodule
