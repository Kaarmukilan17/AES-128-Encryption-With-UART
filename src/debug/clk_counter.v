// -----------------------------------------------------------------------------
// CLK_COUNTER
// -----------------------------------------------------------------------------
module clk_counter (
    input  wire       clk,
    input  wire       rst,
    output reg  [4:0] count
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            count <= 5'd0;
        else
            count <= count + 5'd1;
    end
endmodule
