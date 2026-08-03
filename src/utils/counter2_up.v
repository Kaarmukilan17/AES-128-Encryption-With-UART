// -----------------------------------------------------------------------------
// COUNTER2_UP
// -----------------------------------------------------------------------------
module counter2_up (
    input  wire       clk,
    input  wire       reset,
    input  wire       enable,
    output reg  [1:0] count
);
    always @(posedge clk) begin
        if (reset)       count <= 2'd0;
        else if (enable) count <= count + 2'd1;
    end
endmodule
