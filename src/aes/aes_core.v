// =========================================================
// aes_core.v  —  AES-128 wrapper (Verilog-2001)
// =========================================================

module aes_core (
    input         clk,
    input  [127:0] plaintext,
    input  [127:0] key,
    input          start,
    output [127:0] ciphertext,
    output         done
);
    wire [3:0]    round_cnt;
    wire          sel_final, sel_load, en;
    wire [1407:0] rkey_flat;   // 11 x 128-bit keys flattened
    wire [127:0]  current_rkey;
    wire [127:0]  state_out;

    aes_keyschedule u_ks (
        .key      (key),
        .rkey_flat(rkey_flat)
    );

    // Select rkey[round_cnt] from flat bus
    assign current_rkey = rkey_flat[round_cnt*128 +: 128];

    aes_fsm u_fsm (
        .clk       (clk),
        .start     (start),
        .round_cnt (round_cnt),
        .sel_final (sel_final),
        .sel_load  (sel_load),
        .en        (en),
        .done      (done)
    );

    aes_datapath u_dp (
        .clk       (clk),
        .plaintext (plaintext),
        .round_key (current_rkey),
        .sel_final (sel_final),
        .sel_load  (sel_load),
        .en        (en),
        .state_out (state_out)
    );

    assign ciphertext = state_out;
endmodule
