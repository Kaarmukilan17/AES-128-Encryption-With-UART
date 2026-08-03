// =========================================================
// MixColumns
// =========================================================
module aes_mixcolumns (
    input  [127:0] state_in,
    output [127:0] state_out
);
    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = b[7] ? ({b[6:0],1'b0} ^ 8'h1b) : {b[6:0],1'b0};
        end
    endfunction

    function [31:0] mix_col;
        input [31:0] col;
        reg [7:0] s0,s1,s2,s3,t0,t1,t2,t3;
        begin
            s0=col[31:24]; s1=col[23:16]; s2=col[15:8]; s3=col[7:0];
            t0=xtime(s0);  t1=xtime(s1);  t2=xtime(s2); t3=xtime(s3);
            mix_col[31:24] = t0^(t1^s1)^s2^s3;
            mix_col[23:16] = s0^t1^(t2^s2)^s3;
            mix_col[15:8]  = s0^s1^t2^(t3^s3);
            mix_col[7:0]   = (t0^s0)^s1^s2^t3;
        end
    endfunction

    assign state_out[127:96] = mix_col(state_in[127:96]);
    assign state_out[95:64]  = mix_col(state_in[95:64]);
    assign state_out[63:32]  = mix_col(state_in[63:32]);
    assign state_out[31:0]   = mix_col(state_in[31:0]);
endmodule
