// -----------------------------------------------------------------------------
// MUX4X1_32BIT
// -----------------------------------------------------------------------------
module mux4x1_32bit (
    input  wire [31:0] in0, in1, in2, in3,
    input  wire [1:0]  sel,
    output reg  [31:0] out
);
    always @(*) begin
        case (sel)
            2'd0: out = in0;
            2'd1: out = in1;
            2'd2: out = in2;
            2'd3: out = in3;
        endcase
    end
endmodule
