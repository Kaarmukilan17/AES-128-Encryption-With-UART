// =========================================================
// SubBytes
// =========================================================
module aes_subbytes (
    input  [127:0] state_in,
    output [127:0] state_out
);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sb
            aes_sbox u_sbox (
                .in (state_in [8*i+7 : 8*i]),
                .out(state_out[8*i+7 : 8*i])
            );
        end
    endgenerate
endmodule
