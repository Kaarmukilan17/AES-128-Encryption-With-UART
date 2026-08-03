// =========================================================
// Key Schedule  —  flat 1408-bit output (11 x 128 bits)
//   rkey_flat[127:0]    = rkey[0]
//   rkey_flat[255:128]  = rkey[1]
//   ...
//   rkey_flat[1407:1280]= rkey[10]
// =========================================================
module aes_keyschedule (
    input  [127:0]  key,
    output [1407:0] rkey_flat
);
    wire [7:0] rcon [1:10];
    assign rcon[1]=8'h01; assign rcon[2]=8'h02;
    assign rcon[3]=8'h04; assign rcon[4]=8'h08;
    assign rcon[5]=8'h10; assign rcon[6]=8'h20;
    assign rcon[7]=8'h40; assign rcon[8]=8'h80;
    assign rcon[9]=8'h1b; assign rcon[10]=8'h36;

    // 44 words w[0..43]
    wire [31:0] w [0:43];

    assign w[0] = key[127:96];
    assign w[1] = key[95:64];
    assign w[2] = key[63:32];
    assign w[3] = key[31:0];

    genvar i;
    generate
        for (i = 1; i <= 10; i = i + 1) begin : ks_round
            wire [7:0] rot0, rot1, rot2, rot3;
            wire [7:0] sub0, sub1, sub2, sub3;

            // RotWord
            assign rot0 = w[4*i-1][23:16];
            assign rot1 = w[4*i-1][15:8];
            assign rot2 = w[4*i-1][7:0];
            assign rot3 = w[4*i-1][31:24];

            // SubWord
            aes_sbox sb0(.in(rot0),.out(sub0));
            aes_sbox sb1(.in(rot1),.out(sub1));
            aes_sbox sb2(.in(rot2),.out(sub2));
            aes_sbox sb3(.in(rot3),.out(sub3));

            // Key expansion
            assign w[4*i+0] = w[4*i-4] ^ {sub0^rcon[i], sub1, sub2, sub3};
            assign w[4*i+1] = w[4*i-3] ^ w[4*i+0];
            assign w[4*i+2] = w[4*i-2] ^ w[4*i+1];
            assign w[4*i+3] = w[4*i-1] ^ w[4*i+2];
        end
    endgenerate

    // Pack 11 round keys into flat bus
    // rkey_flat[k*128 +: 128] = {w[4k], w[4k+1], w[4k+2], w[4k+3]}
    genvar r;
    generate
        for (r = 0; r <= 10; r = r + 1) begin : rk_pack
            assign rkey_flat[r*128 +: 128] = {w[4*r], w[4*r+1], w[4*r+2], w[4*r+3]};
        end
    endgenerate
endmodule
