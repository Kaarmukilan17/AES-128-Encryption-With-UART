// =========================================================
// Datapath
// =========================================================
module aes_datapath (
    input         clk,
    input  [127:0] plaintext,
    input  [127:0] round_key,
    input          sel_final,
    input          sel_load,
    input          en,
    output [127:0] state_out
);
    reg  [127:0] state_reg;
    wire [127:0] sub_out, shift_out, mix_out, mux_mix, addrk_out;

    aes_subbytes   u_sub  (.state_in(state_reg),  .state_out(sub_out));
    aes_shiftrows  u_shift(.state_in(sub_out),     .state_out(shift_out));
    aes_mixcolumns u_mix  (.state_in(shift_out),   .state_out(mix_out));

    assign mux_mix   = sel_final ? shift_out : mix_out;
    assign addrk_out = mux_mix ^ round_key;

    always @(posedge clk) begin
        if (en) begin
            if (sel_load)
                state_reg <= plaintext ^ round_key;
            else
                state_reg <= addrk_out;
        end
    end

    assign state_out = state_reg;
endmodule
