// =============================================================================
// tb_aes_subbytes.v
// Testbench for aes_subbytes module
//
// Tests 5 verified input/output pairs computed against NIST AES S-Box.
// All expected outputs cross-verified with Python reference implementation.
//
// Run: iverilog -o tb_sub tb_aes_subbytes.v aes_subbytes.v aes_sbox.v
//      vvp tb_sub
// =============================================================================

`timescale 1ns/1ps

module tb_aes_subbytes;

    // ---- DUT ports ----
    reg  [127:0] state_in;
    wire [127:0] state_out;

    // ---- Instantiate DUT ----
    aes_subbytes uut (
        .state_in (state_in),
        .state_out(state_out)
    );

    // ---- Test tracking ----
    integer pass_cnt = 0;
    integer fail_cnt = 0;

    task check;
        input [127:0] expected;
        input [63:0]  test_num;
        begin
            #10; // small settle time (combinational)
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
        $display("  aes_subbytes Testbench");
        $display("========================================");

        // ------------------------------------------------------------------
        // T1: All-zero input
        // sbox[0x00] = 0x63, so all 16 bytes -> 0x63
        // IN : 00000000000000000000000000000000
        // OUT: 63636363636363636363636363636363
        // ------------------------------------------------------------------
        state_in = 128'h00000000000000000000000000000000;
        check(128'h63636363636363636363636363636363, 1);

        // ------------------------------------------------------------------
        // T2: Incremental nibbles — 00 10 20 30 40 50 60 70 80 90 A0 B0 C0 D0 E0 F0
        // IN : 00102030405060708090A0B0C0D0E0F0
        // OUT: 63CAB7040953D051CD60E0E7BA70E18C
        // ------------------------------------------------------------------
        state_in = 128'h00102030405060708090A0B0C0D0E0F0;
        check(128'h63CAB7040953D051CD60E0E7BA70E18C, 2);

        // ------------------------------------------------------------------
        // T3: Sequential bytes 00..0F
        // IN : 00112233445566778899AABBCCDDEEFF
        // OUT: 638293C31BFC33F5C4EEACEA4BC12816
        // ------------------------------------------------------------------
        state_in = 128'h00112233445566778899AABBCCDDEEFF;
        check(128'h638293C31BFC33F5C4EEACEA4BC12816, 3);

        // ------------------------------------------------------------------
        // T4: NIST Round 1 input (after initial AddRoundKey in NIST vector)
        //     PT XOR key0: 00112233.. XOR 00010203.. = 00101020..
        //     After subbytes of state after ARK = D4E0B81E...
        // IN : D4E0B81E27BFB44111985D52AEF1E530
        // OUT: 48E16C72CC088D8382464C00E4A1D904  (NIST FIPS 197 Appendix B)
        //
        // NOTE: Verilog state ordering is column-major. The Verilog module
        //       processes state_in as a flat 128-bit vector where
        //       state_in[127:120] = byte 0, state_in[7:0] = byte 15.
        //       This test uses that flat ordering directly.
        // ------------------------------------------------------------------
        state_in = 128'hD4E0B81E27BFB44111985D52AEF1E530;
        check(128'h48E16C72CC088D8382464C00E4A1D904, 4);

        // ------------------------------------------------------------------
        // T5: All-FF input
        // sbox[0xFF] = 0x16
        // IN : FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        // OUT: 16161616161616161616161616161616
        // ------------------------------------------------------------------
        state_in = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        check(128'h16161616161616161616161616161616, 5);

        // ---- Summary ----
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
