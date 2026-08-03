// -----------------------------------------------------------------------------
// UART_RX_128
// -----------------------------------------------------------------------------
module uart_rx_128 #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD     = 9600
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        rx,
    output reg [127:0] data_out,

    output wire [7:0]  dbg_rx_data,
    output wire        dbg_rx_valid,
    output reg         dbg_is_hex,
    output wire [5:0]  dbg_hex_count,
    output reg         dbg_enter,
    output wire        dbg_full
);

    wire [7:0] rx_data;
    wire       rx_valid;

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD    (BAUD)
    ) u_uart_rx (
        .clk  (clk),
        .rst  (rst),
        .rx   (rx),
        .data (rx_data),
        .valid(rx_valid)
    );

    assign dbg_rx_data  = rx_data;
    assign dbg_rx_valid = rx_valid;

    function [3:0] ascii_to_hex;
        input [7:0] c;
        begin
            if      (c >= "0" && c <= "9") ascii_to_hex = c - "0";
            else if (c >= "A" && c <= "F") ascii_to_hex = c - "A" + 4'd10;
            else if (c >= "a" && c <= "f") ascii_to_hex = c - "a" + 4'd10;
            else                           ascii_to_hex = 4'h0;
        end
    endfunction

    function is_hex;
        input [7:0] c;
        begin
            is_hex = ((c >= "0" && c <= "9") ||
                      (c >= "A" && c <= "F") ||
                      (c >= "a" && c <= "f"));
        end
    endfunction

    reg [127:0] shift_reg = 128'd0;
    reg [5:0]   hex_count = 6'd0;

    assign dbg_hex_count = hex_count;
    assign dbg_full      = (hex_count == 6'd32);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg  <= 128'd0;
            hex_count  <= 6'd0;
            data_out   <= 128'd0;
            dbg_enter  <= 1'b0;
            dbg_is_hex <= 1'b0;
        end else begin
            dbg_enter  <= 1'b0;
            dbg_is_hex <= 1'b0;

            if (rx_valid) begin
                if (is_hex(rx_data) && hex_count < 6'd32) begin
                    shift_reg  <= {shift_reg[123:0], ascii_to_hex(rx_data)};
                    hex_count  <= hex_count + 6'd1;
                    dbg_is_hex <= 1'b1;
                end
                if (rx_data == 8'h0D) begin
                    data_out  <= shift_reg;
                    shift_reg <= 128'd0;
                    hex_count <= 6'd0;
                    dbg_enter <= 1'b1;
                end
            end
        end
    end

endmodule
