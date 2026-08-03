// =========================================================
// ShiftRows
// =========================================================
module aes_shiftrows (
    input  [127:0] state_in,
    output [127:0] state_out
);
    wire [7:0] s [0:3][0:3];
    genvar r, c;
    generate
        for (c = 0; c < 4; c = c + 1) begin : col_in
            for (r = 0; r < 4; r = r + 1) begin : row_in
                assign s[r][c] = state_in[127-(c*32)-(r*8) -: 8];
            end
        end
    endgenerate

    wire [7:0] sr [0:3][0:3];
    generate
        for (r = 0; r < 4; r = r + 1) begin : sr_row
            for (c = 0; c < 4; c = c + 1) begin : sr_col
                assign sr[r][c] = s[r][(c+r) % 4];
            end
        end
    endgenerate

    generate
        for (c = 0; c < 4; c = c + 1) begin : pack_col
            for (r = 0; r < 4; r = r + 1) begin : pack_row
                assign state_out[127-(c*32)-(r*8) -: 8] = sr[r][c];
            end
        end
    endgenerate
endmodule
