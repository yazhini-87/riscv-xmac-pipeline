
`timescale 1ns/1ps

module tb_xmac;

    // ── inputs ────────────────────────────────────────────────
    reg  [31:0] rs1, rs2, rs3;

    // ── outputs ───────────────────────────────────────────────
    wire [31:0] result;

    // ── test tracking ─────────────────────────────────────────
    integer pass = 0;
    integer fail = 0;

    // ── instantiate XMAC unit ────────────────────────────────
    xmac_unit dut (
        .rs1    (rs1),
        .rs2    (rs2),
        .rs3    (rs3),
        .result (result)
    );

    // ── check task ────────────────────────────────────────────
    task check;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  expected;
        begin
            if (got === expected) begin
                $display("  PASS  %-30s | got=0x%08h (%0d)",
                          name, got, $signed(got));
                pass = pass + 1;
            end else begin
                $display("  FAIL  %-30s | got=0x%08h (%0d) | exp=0x%08h (%0d)",
                          name, got, $signed(got), expected, $signed(expected));
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        $display("==============================");
        $display("  XMAC Unit Testbench");
        $display("  Tests: rd = rs1 * rs2 + rs3");
        $display("==============================");

        // ── TEST 1: Basic MAC ─────────────────────────────────
        // 3 * 4 + 5 = 17
        rs1=32'd3; rs2=32'd4; rs3=32'd5; #10;
        check("3*4+5=17", result, 32'd17);

        // ── TEST 2: Accumulate zero ───────────────────────────
        // 6 * 7 + 0 = 42 (just multiply)
        rs1=32'd6; rs2=32'd7; rs3=32'd0; #10;
        check("6*7+0=42", result, 32'd42);

        // ── TEST 3: FIR step simulation ───────────────────────
        // acc=100, sample=8, coeff=3 → 8*3+100 = 124
        rs1=32'd8; rs2=32'd3; rs3=32'd100; #10;
        check("FIR_step: 8*3+100=124", result, 32'd124);

        // ── TEST 4: Signed multiply ───────────────────────────
        // -2 * 3 + 0 = -6 = 0xFFFFFFFA
        rs1=32'hFFFFFFFE; rs2=32'd3; rs3=32'd0; #10;
        check("signed: -2*3+0=-6", result, 32'hFFFFFFFA);

        // ── TEST 5: Signed × signed ───────────────────────────
        // -2 * -3 + 0 = 6
        rs1=32'hFFFFFFFE; rs2=32'hFFFFFFFD; rs3=32'd0; #10;
        check("signed: -2*-3=6", result, 32'd6);

        // ── TEST 6: Signed accumulate ─────────────────────────
        // -2 * 3 + 10 = -6 + 10 = 4
        rs1=32'hFFFFFFFE; rs2=32'd3; rs3=32'd10; #10;
        check("signed: -2*3+10=4", result, 32'd4);

        // ── TEST 7: 32-bit overflow (lower 32 bits taken) ─────
        // 0x10000 * 0x10000 = 0x100000000 → lower 32 = 0
        rs1=32'h00010000; rs2=32'h00010000; rs3=32'd0; #10;
        check("overflow lower32=0", result, 32'd0);

        // ── TEST 8: 8-tap FIR inner loop simulation ───────────
        // Each iteration: acc = sample[k]*coeff[k] + acc
        // Coefficients: [1,2,3,4,5,6,7,8], Samples: all 1
        // Expected: sum(k*1) for k=1..8 = 36
        begin: fir_loop
            reg [31:0] acc;
            integer k;
            acc = 32'd0;
            for (k = 1; k <= 8; k = k + 1) begin
                rs1 = 32'd1;         // sample = 1
                rs2 = k;             // coeff = k
                rs3 = acc;           // current accumulator
                #10;
                acc = result;        // update accumulator
            end
            check("8-tap FIR: sum(k*1,k=1..8)=36", acc, 32'd36);
        end

        // ── SUMMARY ──────────────────────────────────────────
        $display("==============================");
        $display("  PASSED: %0d / %0d", pass, pass+fail);
        if (fail == 0)
            $display("  ALL TESTS PASSED - XMAC OK!");
        else
            $display("  %0d FAILED - Fix before moving on!", fail);
        $display("==============================");
        $finish;
    end

endmodule
