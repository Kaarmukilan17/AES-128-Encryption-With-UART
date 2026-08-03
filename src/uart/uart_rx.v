// -----------------------------------------------------------------------------
// UART_RX
// -----------------------------------------------------------------------------
module uart_rx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD     = 9600
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;
    localparam IDLE=2'd0, START=2'd1, DATA=2'd2, STOP=2'd3;

    reg [1:0]  state   = IDLE;
    reg [15:0] clk_cnt = 16'd0;
    reg [2:0]  bit_idx = 3'd0;
    reg [7:0]  shift   = 8'd0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            clk_cnt <= 0;
            bit_idx <= 0;
            valid   <= 0;
            data    <= 0;
        end else begin
            valid <= 0;
            case (state)
                IDLE:
                    if (rx == 1'b0) begin
                        clk_cnt <= 0;
                        state   <= START;
                    end
                START:
                    if (clk_cnt == CLKS_PER_BIT/2) begin
                        clk_cnt <= 0;
                        state   <= DATA;
                    end else
                        clk_cnt <= clk_cnt + 1;
                DATA:
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt        <= 0;
                        shift[bit_idx] <= rx;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 0;
                            state   <= STOP;
                        end else
                            bit_idx <= bit_idx + 1;
                    end else
                        clk_cnt <= clk_cnt + 1;
                STOP:
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        data    <= shift;
                        valid   <= 1;
                        clk_cnt <= 0;
                        state   <= IDLE;
                    end else
                        clk_cnt <= clk_cnt + 1;
                default: state <= IDLE;
            endcase
        end
    end

endmodule
