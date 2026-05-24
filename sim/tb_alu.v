module tb_alu;

    // ── inputs (reg so we can drive them) ────────────────────
    reg  [31:0] a, b;
    reg  [3:0]  alu_op;

    // ── outputs (wire, driven by DUT) ────────────────────────
    wire [31:0] result;
    wire        zero;

    // ── test tracking ─────────────────────────────────────────
    integer pass = 0;
    integer fail = 0;

    // ── instantiate ALU (Device Under Test) ──────────────────
    alu dut (
        .a      (a),
        .b      (b),
        .alu_op (alu_op),
        .result (result),
        .zero   (zero)
    );

    // ── task: check result ────────────────────────────────────
    // Usage: check("ADD", result, expected_value);
    task check;
        input [63:0] op_name;  // operation name for display
        input [31:0] got;      // actual result from DUT
        input [31:0] expected; // what we expect
        begin
            if (got === expected) begin
                $display("  PASS  %-8s | got=0x%08h", op_name, got);
                pass = pass + 1;
            end else begin
                $display("  FAIL  %-8s | got=0x%08h | expected=0x%08h",
                          op_name, got, expected);
                fail = fail + 1;
            end
        end
    endtask

    // ── main test sequence ────────────────────────────────────
    initial begin
        $display("==============================");
        $display("  ALU Testbench Starting");
        $display("==============================");

        // Small delay so signals settle
        #10;

        // ── TEST 1: ADD ──────────────────────────────────────
        // 5 + 3 = 8
        a = 32'd5; b = 32'd3; alu_op = 4'b0000; #10;
        check("ADD", result, 32'd8);

        // ── TEST 2: ADD negative ─────────────────────────────
        // -1 + 1 = 0  (0xFFFFFFFF + 1 wraps to 0)
        a = 32'hFFFFFFFF; b = 32'd1; alu_op = 4'b0000; #10;
        check("ADD_OVF", result, 32'd0);

        // ── TEST 3: SUB ──────────────────────────────────────
        // 10 - 3 = 7
        a = 32'd10; b = 32'd3; alu_op = 4'b1000; #10;
        check("SUB", result, 32'd7);

        // ── TEST 4: SUB same values → zero flag ──────────────
        // 5 - 5 = 0, zero should be 1
        a = 32'd5; b = 32'd5; alu_op = 4'b1000; #10;
        check("SUB_ZERO", result, 32'd0);
        if (zero !== 1'b1) begin
            $display("  FAIL  ZERO_FLAG | zero=%b expected=1", zero);
            fail = fail + 1;
        end else begin
            $display("  PASS  ZERO_FLAG | zero=1 (BEQ would branch)");
            pass = pass + 1;
        end

        // ── TEST 5: AND ──────────────────────────────────────
        // 0xFF00FF00 & 0x0F0F0F0F = 0x0F000F00
        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alu_op = 4'b0111; #10;
        check("AND", result, 32'h0F000F00);

        // ── TEST 6: OR ───────────────────────────────────────
        // 0xF0F0F0F0 | 0x0F0F0F0F = 0xFFFFFFFF
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = 4'b0110; #10;
        check("OR", result, 32'hFFFFFFFF);

        // ── TEST 7: XOR ──────────────────────────────────────
        // 0xAAAAAAAA ^ 0x55555555 = 0xFFFFFFFF
        a = 32'hAAAAAAAA; b = 32'h55555555; alu_op = 4'b0100; #10;
        check("XOR", result, 32'hFFFFFFFF);

        // ── TEST 8: SLT (signed less than) ───────────────────
        // -1 < 1 (signed) → result = 1
        a = 32'hFFFFFFFF; b = 32'd1; alu_op = 4'b0010; #10;
        check("SLT_NEG", result, 32'd1);

        // 5 < 3 (signed) → result = 0
        a = 32'd5; b = 32'd3; alu_op = 4'b0010; #10;
        check("SLT_POS", result, 32'd0);

        // ── TEST 9: SLTU (unsigned) ──────────────────────────
        // 0xFFFFFFFF < 1 unsigned? NO → 0
        a = 32'hFFFFFFFF; b = 32'd1; alu_op = 4'b0011; #10;
        check("SLTU", result, 32'd0);

        // ── TEST 10: SLL (shift left logical) ────────────────
        // 1 << 4 = 16
        a = 32'd1; b = 32'd4; alu_op = 4'b0001; #10;
        check("SLL", result, 32'd16);

        // ── TEST 11: SRL (shift right logical) ───────────────
        // 0x80000000 >> 1 = 0x40000000 (zero fill)
        a = 32'h80000000; b = 32'd1; alu_op = 4'b0101; #10;
        check("SRL", result, 32'h40000000);

        // ── TEST 12: SRA (shift right arithmetic) ────────────
        // 0x80000000 >>> 1 = 0xC0000000 (sign fill)
        a = 32'h80000000; b = 32'd1; alu_op = 4'b1101; #10;
        check("SRA", result, 32'hC0000000);

        // ── SUMMARY ──────────────────────────────────────────
        $display("==============================");
        $display("  PASSED: %0d / %0d", pass, pass+fail);
        if (fail == 0)
            $display("  ALL TESTS PASSED - ALU OK!");
        else
            $display("  %0d TESTS FAILED - Fix before moving on!", fail);
        $display("==============================");
        $finish;
    end

endmodule
