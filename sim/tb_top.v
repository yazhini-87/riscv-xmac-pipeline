`timescale 1ns/1ps

module tb_top;

    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk;

    integer pass = 0;
    integer fail = 0;
    integer test_num = 0;

    riscv_top dut (
        .clk (clk),
        .rst (rst)
    );

    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_top);
    end

    // ── pipeline debug monitor ────────────────────────────────
    always @(posedge clk) begin
        if (!rst) begin
            $display("t=%0t | EX_rd=x%0d EX_alu=%0d | MEM_rd=x%0d | WB_rd=x%0d wb_we=%b wb_data=%0d",
                $time,
                dut.ex_rd,
                dut.ex_alu_result,
                dut.mem_rd,
                dut.wb_rd,
                dut.wb_reg_write,
                dut.wb_data);
        end
    end
    // XMAC debug monitor - add to tb_top.v
always @(posedge clk) begin
    // Print when XMAC instruction is in ID stage
    if (!rst && dut.id_instr == 32'h60B5068B) begin
        $display("XMAC_IN_ID: rs3=%0d rs3_data=%0d xmac_en=%b rd=%0d",
            dut.id_rs3, dut.id_rs3_data,
            dut.id_xmac_en, dut.id_rd);
    end
    // Print when XMAC is in EX stage
    if (!rst && dut.ex_xmac_en) begin
        $display("XMAC_IN_EX: ex_rs3=%0d ex_rs3_data=%0d fwd_c=%b op_c=%0d xmac_out=%0d",
            dut.ex_rs3, dut.ex_rs3_data,
            dut.fwd_c, dut.u_ex.op_c,
            dut.u_ex.xmac_out);
    end
end

    // ── read register ─────────────────────────────────────────
    function [31:0] read_reg;
        input [4:0] idx;
        begin
            read_reg = (idx == 0) ? 32'b0
                     : dut.u_id.u_rf.regs[idx]; // ✅ u_rf not u_regfile
        end
    endfunction

    // ── check task ────────────────────────────────────────────
    task check_reg;
        input [4:0]   reg_idx;
        input [31:0]  expected;
        input [255:0] test_name;
        reg   [31:0]  got;
        begin
            got = read_reg(reg_idx);
            test_num = test_num + 1;
            if (got === expected) begin
                $display("  PASS  Test%02d %-30s | x%0d=0x%08h",
                    test_num, test_name, reg_idx, got);
                pass = pass + 1;
            end else begin
                $display("  FAIL  Test%02d %-30s | x%0d=0x%08h expected=0x%08h",
                    test_num, test_name, reg_idx, got, expected);
                fail = fail + 1;
            end
        end
    endtask

    // ── test tasks ────────────────────────────────────────────
    task test_basic_arithmetic;
        begin
            $display("\n--- Test Group 1: Basic Arithmetic ---");
            dut.u_if.imem[0] = 32'h00500513; // ADDI x10,x0,5
            dut.u_if.imem[1] = 32'h00300593; // ADDI x11,x0,3
            dut.u_if.imem[2] = 32'h00B50633; // ADD  x12,x10,x11
            dut.u_if.imem[3] = 32'h40B606B3; // SUB  x13,x12,x11
            dut.u_if.imem[4] = 32'h00000013; // NOP
            dut.u_if.imem[5] = 32'h00000013; // NOP
            dut.u_if.imem[6] = 32'h00000013; // NOP
            dut.u_if.imem[7] = 32'h00000013; // NOP
            // ✅ Correct reset sequence
            rst = 1; repeat(5) @(posedge clk); rst = 0;
            repeat(20) @(posedge clk);
            check_reg(10, 32'd5, "ADDI x10=5");
            check_reg(11, 32'd3, "ADDI x11=3");
            check_reg(12, 32'd8, "ADD  x12=x10+x11=8");
            check_reg(13, 32'd5, "SUB  x13=x12-x11=5");
        end
    endtask

    task test_forwarding;
        begin
            $display("\n--- Test Group 2: Forwarding ---");
            dut.u_if.imem[0] = 32'h00A00513; // ADDI x10,x0,10
            dut.u_if.imem[1] = 32'h00A50533; // ADD  x10,x10,x10
            dut.u_if.imem[2] = 32'h00A50533; // ADD  x10,x10,x10
            dut.u_if.imem[3] = 32'h00A50533; // ADD  x10,x10,x10
            dut.u_if.imem[4] = 32'h00000013;
            dut.u_if.imem[5] = 32'h00000013;
            dut.u_if.imem[6] = 32'h00000013;
            dut.u_if.imem[7] = 32'h00000013;
            rst = 1; repeat(5) @(posedge clk); rst = 0;
            repeat(15) @(posedge clk);
            check_reg(10, 32'd80, "FWD x10=10->20->40->80");
        end
    endtask

    task test_load_use_hazard;
        begin
            $display("\n--- Test Group 3: Load-Use Hazard ---");
            dut.u_mem.dmem[0] = 32'h00000007;
            dut.u_if.imem[0] = 32'h00002503; // LW   x10,0(x0)
            dut.u_if.imem[1] = 32'h00A50593; // ADDI x11,x10,10
            dut.u_if.imem[2] = 32'h00000013;
            dut.u_if.imem[3] = 32'h00000013;
            dut.u_if.imem[4] = 32'h00000013;
            dut.u_if.imem[5] = 32'h00000013;
            rst = 1; repeat(5) @(posedge clk); rst = 0;
            repeat(18) @(posedge clk);
            check_reg(10, 32'd7,  "LW x10=7 from dmem[0]");
            check_reg(11, 32'd17, "ADDI x11=x10+10=17 (after stall)");
        end
    endtask

    task test_store_load;
        begin
            $display("\n--- Test Group 4: Store then Load ---");
            dut.u_if.imem[0] = 32'h02A00513; // ADDI x10,x0,42
            dut.u_if.imem[1] = 32'h00A02023; // SW   x10,0(x0)
            dut.u_if.imem[2] = 32'h00002583; // LW   x11,0(x0)
            dut.u_if.imem[3] = 32'h00000013;
            dut.u_if.imem[4] = 32'h00000013;
            dut.u_if.imem[5] = 32'h00000013;
            dut.u_if.imem[6] = 32'h00000013;
            rst = 1; repeat(35) @(posedge clk); rst = 0;
            repeat(18) @(posedge clk);
            check_reg(10, 32'd42, "SW: x10=42");
            check_reg(11, 32'd42, "LW: x11=mem[0]=42");
        end
    endtask

task test_xmac;
    begin
        $display("\n--- Test Group 5: XMAC Custom Instruction ---");

        force dut.u_id.u_rf.regs[10] = 32'b0;
        force dut.u_id.u_rf.regs[11] = 32'b0;
        force dut.u_id.u_rf.regs[12] = 32'b0;
        force dut.u_id.u_rf.regs[13] = 32'b0;
        #1;
        release dut.u_id.u_rf.regs[10];
        release dut.u_id.u_rf.regs[11];
        release dut.u_id.u_rf.regs[12];
        release dut.u_id.u_rf.regs[13];

        dut.u_if.imem[0]  = 32'h00300513; // ADDI x10,x0,3
        dut.u_if.imem[1]  = 32'h00400593; // ADDI x11,x0,4
        dut.u_if.imem[2]  = 32'h00500613; // ADDI x12,x0,5
        dut.u_if.imem[3]  = 32'h00000013; // NOP
        dut.u_if.imem[4]  = 32'h00000013; // NOP
        dut.u_if.imem[5]  = 32'h00000013; // NOP
        dut.u_if.imem[6]  = 32'h00000013; // NOP
        dut.u_if.imem[7]  = 32'h60B5068B; // XMAC x13,x10,x11,x12
        dut.u_if.imem[8]  = 32'h00000013; // NOP
        dut.u_if.imem[9]  = 32'h00000013; // NOP
        dut.u_if.imem[10] = 32'h00000013; // NOP
        dut.u_if.imem[11] = 32'h00000013; // NOP

        rst = 1; repeat(5) @(posedge clk); rst = 0;

        // ── Cycle by cycle trace ──────────────────────────
        repeat(25) begin
            @(posedge clk);
            $display("t=%0t PC=%h | EX_rd=x%0d alu=%0d xmac_en=%b | fwd_a=%b fwd_b=%b fwd_c=%b | op_a=%0d op_b=%0d op_c=%0d | xmac=%0d | wb_rd=x%0d wb=%0d",
                $time,
                dut.u_if.pc,
                dut.ex_rd,
                dut.ex_alu_result,
                dut.ex_xmac_en,
                dut.fwd_a,
                dut.fwd_b,
                dut.fwd_c,
                dut.u_ex.op_a,
                dut.u_ex.op_b_reg,
                dut.u_ex.op_c,
                dut.u_ex.xmac_out,
                dut.wb_rd,
                dut.wb_data);
        end

        check_reg(10, 32'd3,  "ADDI x10=3");
        check_reg(11, 32'd4,  "ADDI x11=4");
        check_reg(12, 32'd5,  "ADDI x12=5");
        check_reg(13, 32'd17, "XMAC x13=3*4+5=17");
    end
endtask
    // ── run all tests ─────────────────────────────────────────
    initial begin
        $display("============================================");
        $display("  RISC-V RV32I + XMAC Pipeline Testbench");
        $display("============================================");

        // ✅ Correct: just hold reset then release once
        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);

        test_basic_arithmetic;
        test_forwarding;
        test_load_use_hazard;
        test_store_load;
        test_xmac;

        $display("\n============================================");
        $display("  FINAL RESULTS");
        $display("  PASSED : %0d", pass);
        $display("  FAILED : %0d", fail);
        $display("  TOTAL  : %0d", pass + fail);
        $display("============================================");
        if (fail == 0)
            $display("  ALL TESTS PASSED!");
        else
            $display("  SOME TESTS FAILED - check waveform");
        $display("============================================");
        $finish;
    end

    initial begin
        #200000;
        $display("TIMEOUT");
        $finish;
    end

endmodule