// -----------------------------------------------------------------------------
// DEBOUNCE
// -----------------------------------------------------------------------------
module debounce (
    input  wire clk,
    input  wire btn_in,
    output reg  btn_out
);
    reg [19:0] cnt  = 0;
    reg        sync = 0;
    always @(posedge clk) begin
        sync <= btn_in;
        if (sync == btn_out)
            cnt <= 0;
        else begin
            cnt <= cnt + 1;
            if (cnt == 20'hFFFFF)
                btn_out <= sync;
        end
    end
endmodule
