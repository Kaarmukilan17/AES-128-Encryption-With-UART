// =============================================================================
// tb_aes_keyschedule.v
// Testbench for aes_keyschedule module
//
// aes_keyschedule is fully combinational. It takes a 128-bit key and
// produces rkey_flat[1407:0] = all 11 round keys packed flat.
// rkey_flat[k*128 +: 128] = round key k
//
// 3 full key expansions tested:
//   KEY1: 000102030405060708090A0B0C0D0E0F  (NIST FIPS 197 Appendix A.1)
//   KEY2: 2B7E151628AED2A6ABF7158809CF4F3C  (NIST FIPS 197 Appendix B)
//   KEY3: 00000000000000000000000000000000  (all-zero key)
//
// All round keys verified against Python reference implementation.
//
// Run: iverilog -o tb_ks tb_aes_keyschedule.v aes_keyschedule.v aes_sbox.v
//      vvp tb_ks
// =============================================================================

`timescale 1ns/1ps

module tb_aes_keyschedule;

    reg  [127:0] key;
    wire [1407:0] rkey_flat;

    aes_keyschedule uut (
        .key      (key),
        .rkey_flat(rkey_flat)
    );

    integer pass_cnt = 0;
    integer fail_cnt = 0;
    integer total    = 0;

    // Extract round key r from flat output
    function [127:0] get_rkey;
        input [1407:0] flat;
        input integer  r;
        begin
            get_rkey = flat[r*128 +: 128];
        end
    endfunction

    task check_rkey;
        input integer  round;
        input [127:0]  expected;
        reg   [127:0]  actual;
        begin
            actual = get_rkey(rkey_flat, round);
            total  = total + 1;
            if (actual === expected) begin
                $display("  PASS rkey[%02d] = %032X", round, actual);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  FAIL rkey[%02d]", round);
                $display("    EXP = %032X", expected);
                $display("    GOT = %032X", actual);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    initial begin
        $display("========================================");
        $display("  aes_keyschedule Testbench");
        $display("========================================");

        // ==================================================================
        // KEY 1: 000102030405060708090A0B0C0D0E0F
        // NIST FIPS 197 Appendix A.1 — verified reference
        // ==================================================================
        $display("");
        $display("--- KEY1: 000102030405060708090A0B0C0D0E0F ---");
        key = 128'h000102030405060708090A0B0C0D0E0F;
        #20; // combinational settle

        check_rkey( 0, 128'h000102030405060708090A0B0C0D0E0F);
        check_rkey( 1, 128'hD6AA74FDD2AF72FADAA678F1D6AB76FE);
        check_rkey( 2, 128'hB692CF0B643DBDF1BE9BC5006830B3FE);
        check_rkey( 3, 128'hB6FF744ED2C2C9BF6C590CBF0469BF41);
        check_rkey( 4, 128'h47F7F7BC95353E03F96C32BCFD058DFD);
        check_rkey( 5, 128'h3CAAA3E8A99F9DEB50F3AF57ADF622AA);
        check_rkey( 6, 128'h5E390F7DF7A69296A7553DC10AA31F6B);
        check_rkey( 7, 128'h14F9701AE35FE28C440ADF4D4EA9C026);
        check_rkey( 8, 128'h47438735A41C65B9E016BAF4AEBF7AD2);
        check_rkey( 9, 128'h549932D1F08557681093ED9CBE2C974E);
        check_rkey(10, 128'h13111D7FE3944A17F307A78B4D2B30C5);

        // ==================================================================
        // KEY 2: 2B7E151628AED2A6ABF7158809CF4F3C
        // NIST FIPS 197 Appendix B — AES-128 main spec example
        // ==================================================================
        $display("");
        $display("--- KEY2: 2B7E151628AED2A6ABF7158809CF4F3C ---");
        key = 128'h2B7E151628AED2A6ABF7158809CF4F3C;
        #20;

        check_rkey( 0, 128'h2B7E151628AED2A6ABF7158809CF4F3C);
        check_rkey( 1, 128'hA0FAFE1788542CB123A339392A6C7605);
        check_rkey( 2, 128'hF2C295F27A96B9435935807A7359F67F);
        check_rkey( 3, 128'h3D80477D4716FE3E1E237E446D7A883B);
        check_rkey( 4, 128'hEF44A541A8525B7FB671253BDB0BAD00);
        check_rkey( 5, 128'hD4D1C6F87C839D87CAF2B8BC11F915BC);
        check_rkey( 6, 128'h6D88A37A110B3EFDDBF98641CA0093FD);
        check_rkey( 7, 128'h4E54F70E5F5FC9F384A64FB24EA6DC4F);
        check_rkey( 8, 128'hEAD27321B58DBAD2312BF5607F8D292F);
        check_rkey( 9, 128'hAC7766F319FADC2128D12941575C006E);
        check_rkey(10, 128'hD014F9A8C9EE2589E13F0CC8B6630CA6);

        // ==================================================================
        // KEY 3: 00000000000000000000000000000000
        // All-zero key — tests rcon propagation and sbox[0x00]=0x63 path
        // ==================================================================
        $display("");
        $display("--- KEY3: 00000000000000000000000000000000 ---");
        key = 128'h00000000000000000000000000000000;
        #20;

        check_rkey( 0, 128'h00000000000000000000000000000000);
        check_rkey( 1, 128'h62636363626363636263636362636363);
        check_rkey( 2, 128'h9B9898C9F9FBFBAA9B9898C9F9FBFBAA);
        check_rkey( 3, 128'h90973450696CCFFAF2F457330B0FAC99);
        check_rkey( 4, 128'hEE06DA7B876A1581759E42B27E91EE2B);
        check_rkey( 5, 128'h7F2E2B88F8443E098DDA7CBBF34B9290);
        check_rkey( 6, 128'hEC614B851425758C99FF09376AB49BA7);
        check_rkey( 7, 128'h217517873550620BACAF6B3CC61BF09B);
        check_rkey( 8, 128'h0EF903333BA9613897060A04511DFA9F);
        check_rkey( 9, 128'hB1D4D8E28A7DB9DA1D7BB3DE4C664941);
        check_rkey(10, 128'hB4EF5BCB3E92E21123E951CF6F8F188E);

        // ---- Summary ----
        $display("");
        $display("========================================");
        $display("  PASSED: %0d / %0d", pass_cnt, total);
        $display("  FAILED: %0d / %0d", fail_cnt, total);
        if (fail_cnt == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED — check above");
        $display("========================================");
        $finish;
    end

endmodule
