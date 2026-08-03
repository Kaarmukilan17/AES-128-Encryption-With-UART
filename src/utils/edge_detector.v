// -----------------------------------------------------------------------------
// EDGE_DETECTOR
// -----------------------------------------------------------------------------
module edge_detector (
    input  wire clk,
    input  wire signal_in,
    output wire pulse_out
);
    reg prev = 0;
    always @(posedge clk) prev <= signal_in;
    assign pulse_out = signal_in & ~prev;
endmodule
