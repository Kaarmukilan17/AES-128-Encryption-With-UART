// =========================================================
// FSM
// =========================================================
module aes_fsm (
    input            clk,
    input            start,
    output reg [3:0] round_cnt,
    output reg       sel_final,
    output reg       sel_load,
    output reg       en,
    output reg       done
);
    localparam IDLE        = 3'd0,
               INIT        = 3'd1,
               ROUND       = 3'd2,
               FINAL_ROUND = 3'd3,
               DONE_ST     = 3'd4;

    reg [2:0] state, next_state;

    always @(posedge clk)
        state <= next_state;

    always @(posedge clk) begin
        case (state)
            INIT:        round_cnt <= 4'd1;
            ROUND:       round_cnt <= round_cnt + 4'd1;
            FINAL_ROUND: round_cnt <= 4'd0;
            default:     round_cnt <= 4'd0;
        endcase
    end

    always @(*) begin
        case (state)
            IDLE:        next_state = start             ? INIT        : IDLE;
            INIT:        next_state = ROUND;
            ROUND:       next_state = (round_cnt==4'd9) ? FINAL_ROUND : ROUND;
            FINAL_ROUND: next_state = DONE_ST;
            DONE_ST:     next_state = IDLE;
            default:     next_state = IDLE;
        endcase
    end

    always @(*) begin
        sel_final = 1'b0;
        sel_load  = 1'b0;
        en        = 1'b0;
        done      = 1'b0;
        case (state)
            IDLE:        en = 1'b0;
            INIT:      begin sel_load = 1'b1; en = 1'b1; end
            ROUND:     begin sel_final = 1'b0; en = 1'b1; end
            FINAL_ROUND:begin sel_final = 1'b1; en = 1'b1; end
            DONE_ST:   begin done = 1'b1; en = 1'b0; end
        endcase
    end
endmodule
