
`timescale 1ns/1ps

module tb_regfile;

    // ── inputs ────────────────────────────────────────────────
    reg        clk, we;
    reg  [4:0] rs1, rs2, rs3, rd;
    reg [31:0] wd;

    // ── outputs ───────────────────────────────────────────────
    wire [31:0] rd1, rd2, rd3;

    // ── test tracking ─────────────────────────────────────────
    integer pass = 0;
    integer fail = 0;

    // ── clock: 10ns period ────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── instantiate regfile ───────────────────────────────────
    regfile dut (
        .clk (clk),
        .we  (we),
        .rs1 (rs1), .rs2 (rs2), .rs3 (rs3),
        .rd  (rd),  .wd  (wd),
        .rd1 (rd1), .rd2 (rd2), .rd3 (rd3)
    );

    // ── check task ────────────────────────────────────────────
    task check;
        input [127:0] name;
        input [31:0]  got;
        input [31:0]  expected;
        begin
            if (got === expected) begin
                $display("  PASS  %-20s | got=0x%08h", name, got);
                pass = pass + 1;
            end else begin
                $display("  FAIL  %-20s | got=0x%08h | expected=0x%08h",
                          name, got, expected);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        $display("==============================");
        $display("  Regfile Testbench Starting");
        $display("==============================");

        // ── safe initial state ────────────────────────────────
        we = 0; rd = 0; wd = 0;
        rs1 = 0; rs2 = 0; rs3 = 0;
        @(posedge clk); #1;

        // ── TEST 1: write x10 = 0xDEADBEEF ──────────────────
        we = 1; rd = 5'd10; wd = 32'hDEADBEEF;
        @(posedge clk); #1;
        we = 0;
        // now read back via rs1
        rs1 = 5'd10;
        #5; // combinational read settles
        check("write/read x10", rd1, 32'hDEADBEEF);

        // ── TEST 2: write x5 = 0xCAFEBABE ────────────────────
        we = 1; rd = 5'd5; wd = 32'hCAFEBABE;
        @(posedge clk); #1;
        we = 0;
        rs2 = 5'd5; #5;
        check("write/read x5", rd2, 32'hCAFEBABE);

        // ── TEST 3: x0 always reads 0 (write attempt) ────────
        we = 1; rd = 5'd0; wd = 32'hFFFFFFFF; // try to write x0
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd0; #5;
        check("x0 always zero", rd1, 32'd0);

        // ── TEST 4: three simultaneous reads ─────────────────
        // write x15=111, x20=222, x25=333 first
        we=1; rd=5'd15; wd=32'd111; @(posedge clk); #1;
        rd=5'd20; wd=32'd222; @(posedge clk); #1;
        rd=5'd25; wd=32'd333; @(posedge clk); #1;
        we=0;
        rs1=5'd15; rs2=5'd20; rs3=5'd25; #5;
        check("3-port read rs1", rd1, 32'd111);
        check("3-port read rs2", rd2, 32'd222);
        check("3-port read rs3", rd3, 32'd333); // XMAC port

        // ── TEST 5: write then immediate read (same cycle) ───
        // WB writes x7, ID reads x7 - half cycle trick
        we=1; rd=5'd7; wd=32'd999;
        rs1=5'd7; // read same cycle as write
        @(posedge clk); #1; // write happens
        we=0; #5;
        // after clock, read should see 999
        check("write-then-read x7", rd1, 32'd999);

        // ── SUMMARY ──────────────────────────────────────────
        $display("==============================");
        $display("  PASSED: %0d / %0d", pass, pass+fail);
        if (fail == 0)
            $display("  ALL TESTS PASSED - Regfile OK!");
        else
            $display("  %0d FAILED - Fix before moving on!", fail);
        $display("==============================");
        $finish;
    end

endmodule
