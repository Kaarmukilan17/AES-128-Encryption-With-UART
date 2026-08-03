// -----------------------------------------------------------------------------
// EIGHT_SEVENSEG_32BIT
// -----------------------------------------------------------------------------
module eight_sevenseg_32bit (
    input  wire [31:0] data32,
    output wire [6:0]  seg0, seg1, seg2, seg3, seg4, seg5, seg6, seg7
);
    hex_to_7seg d0(.hex(data32[3:0]),   .seg(seg0));
    hex_to_7seg d1(.hex(data32[7:4]),   .seg(seg1));
    hex_to_7seg d2(.hex(data32[11:8]),  .seg(seg2));
    hex_to_7seg d3(.hex(data32[15:12]), .seg(seg3));
    hex_to_7seg d4(.hex(data32[19:16]), .seg(seg4));
    hex_to_7seg d5(.hex(data32[23:20]), .seg(seg5));
    hex_to_7seg d6(.hex(data32[27:24]), .seg(seg6));
    hex_to_7seg d7(.hex(data32[31:28]), .seg(seg7));
endmodule
