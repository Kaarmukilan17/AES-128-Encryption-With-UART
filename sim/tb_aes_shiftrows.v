// =============================================================================
// tb_aes_shiftrows.v
// Testbench for aes_shiftrows module
//
// ShiftRows cyclically shifts rows of the 4x4 state matrix left:
//   Row 0: no shift
//   Row 1: shift left 1
//   Row 2: shift left 2
//   Row 3: shift left 3
//
// Verilog state is column-major and packed as a flat 128-bit vector:
//   state[127:120]=byte(row0,col0), state[119:112]=byte(row1,col0), ...
//
// Run: iverilog -o tb_sr tb_aes_shiftrows.v aes_shiftrows.v
//      vvp tb_sr
// =============================================================================

`timescale 1ns/1ps

module tb_aes_shiftrows;

    reg  [127:0] state_in;
    wire [127:0] state_out;

    aes_shiftrows uut (
        .state_in (state_in),
        .state_out(state_out)
    );

    integer pass_cnt = 0;
    integer fail_cnt = 0;

    task check;
        input [127:0] expected;
        input [63:0]  test_num;
        begin
            #10;
            if (state_out === expected) begin
                $display("PASS [T%0d] IN=%032X  OUT=%032X", test_num, state_in, state_out);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("FAIL [T%0d] IN=%032X", test_num, state_in);
                $display("          EXP=%032X", expected);
                $display("          GOT=%032X", state_out);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    initial begin
        $display("========================================");
        $display("  aes_shiftrows Testbench");
        $display("========================================");

        // ------------------------------------------------------------------
        // T1: NIST FIPS 197 Appendix B — input after SubBytes round 1
        //     State matrix (col-major, bytes top-to-bottom then left-to-right):
        //     D4  E0  B8  1E
        //     BF  B4  41  27
        //     5D  52  11  98
        //     30  AE  F1  E5
        //
        //     After ShiftRows:
        //     Row 0 (no shift):  D4  E0  B8  1E
        //     Row 1 (shift 1):   B4  41  27  BF
        //     Row 2 (shift 2):   11  98  5D  52
        //     Row 3 (shift 3):   AE  F1  E5  30
        //
        //     Packed flat (col-major):
        //     Col0: D4 B4 11 AE -> D4B411AE
        //     Col1: E0 41 98 F1 -> E04198F1
        //     Col2: B8 27 5D E5 -> B8275DE5
        //     Col3: 1E BF 52 30 -> 1EBF5230
        //
        // IN : D4E0B81EBFB441275D52119830AEF1E5
        // OUT: D4B411AEE04198F1B8275DE51EBF5230
        // ------------------------------------------------------------------
        state_in = 128'hD4E0B81EBFB441275D52119830AEF1E5;
        check(128'hD4B411AEE04198F1B8275DE51EBF5230, 1);

        // ------------------------------------------------------------------
        // T2: Incremental nibbles (row visibility test)
        // State matrix (col-major):
        //   00 40 80 C0
        //   10 50 90 D0
        //   20 60 A0 E0
        //   30 70 B0 F0
        // After ShiftRows:
        //   Row0 no-shift: 00 40 80 C0
        //   Row1 shift1:   50 90 D0 10
        //   Row2 shift2:   A0 E0 20 60
        //   Row3 shift3:   F0 30 70 B0
        // Packed: col0=00 50 A0 F0, col1=40 90 E0 30, col2=80 D0 20 70, col3=C0 10 60 B0
        // IN : 00102030405060708090A0B0C0D0E0F0
        // OUT: 0050A0F04090E03080D02070C01060B0
        // ------------------------------------------------------------------
        state_in = 128'h00102030405060708090A0B0C0D0E0F0;
        check(128'h0050A0F04090E03080D02070C01060B0, 2);

        // ------------------------------------------------------------------
        // T3: NIST key schedule intermediate (Round 2 SubBytes output)
        // IN : A0FAFE1788542CB123A339392A6C7605
        // OUT: A054390588A37617236CFEB12AFA2C39
        // ------------------------------------------------------------------
        state_in = 128'hA0FAFE1788542CB123A339392A6C7605;
        check(128'hA054390588A37617236CFEB12AFA2C39, 3);

        // ------------------------------------------------------------------
        // T4: All-FF — ShiftRows of uniform state is identity
        // IN : FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        // OUT: FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        // ------------------------------------------------------------------
        state_in = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        check(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 4);

        // ------------------------------------------------------------------
        // T5: All-zero — ShiftRows of zero state is zero
        // IN : 00000000000000000000000000000000
        // OUT: 00000000000000000000000000000000
        // ------------------------------------------------------------------
        state_in = 128'h00000000000000000000000000000000;
        check(128'h00000000000000000000000000000000, 5);

        $display("========================================");
        $display("  PASSED: %0d / 5", pass_cnt);
        $display("  FAILED: %0d / 5", fail_cnt);
        if (fail_cnt == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED — check above");
        $display("========================================");
        $finish;
    end

endmodule
