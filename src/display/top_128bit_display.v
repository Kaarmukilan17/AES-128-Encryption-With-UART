// -----------------------------------------------------------------------------
// TOP_128BIT_DISPLAY
// -----------------------------------------------------------------------------
module top_128bit_display (
    input  wire         clk,
    input  wire         reset,
    input  wire         btn,
    input  wire [127:0] data,
    output wire [6:0]  seg0,
    output wire [6:0]  seg1,
    output wire [6:0]  seg2,
    output wire [6:0]  seg3,
    output wire [6:0]  seg4,
    output wire [6:0]  seg5,
    output wire [6:0]  seg6,
    output wire [6:0]  seg7,
    output wire [1:0]  status_led
);

    wire        btn_clean;
    wire        btn_pulse;
    wire [1:0]  seg_sel;
    wire [31:0] seg_data;

    debounce db_inst (
        .clk    (clk),
        .btn_in (btn),
        .btn_out(btn_clean)
    );

    edge_detector edge_inst (
        .clk      (clk),
        .signal_in(btn_clean),
        .pulse_out(btn_pulse)
    );

    counter2_up counter_inst (
        .clk   (clk),
        .reset (reset),
        .enable(btn_pulse),
        .count (seg_sel)
    );

    mux4x1_32bit mux_inst (
        .in0(data[31:0]),
        .in1(data[63:32]),
        .in2(data[95:64]),
        .in3(data[127:96]),
        .sel(seg_sel),
        .out(seg_data)
    );

    eight_sevenseg_32bit disp_inst (
        .data32(seg_data),
        .seg0  (seg0), .seg1(seg1), .seg2(seg2), .seg3(seg3),
        .seg4  (seg4), .seg5(seg5), .seg6(seg6), .seg7(seg7)
    );

    assign status_led = seg_sel;

endmodule
