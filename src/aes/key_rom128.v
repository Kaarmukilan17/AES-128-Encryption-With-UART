  module key_rom128 (
    input  wire        clk,
    input  wire [3:0]  addr,
    output reg  [127:0] key_out
);

    reg [127:0] mem [0:15];

    initial begin
        $readmemh("key.txt", mem);
    end

    always @(posedge clk)
        key_out <= mem[addr];

endmodule
