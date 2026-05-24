`timescale 1ns/1ps
 
module tb_imm_ext;
 
    // ── inputs ────────────────────────────────────────────────
    reg  [31:0] instr;
 
    // ── outputs ───────────────────────────────────────────────
    wire [31:0] imm;
 
    // ── test tracking ─────────────────────────────────────────
    integer pass = 0;
    integer fail = 0;
 
    // ── instantiate imm_ext (Device Under Test) ───────────────
    imm_ext dut (
        .instr (instr),
        .imm   (imm)
    );
 
    // ── check task ────────────────────────────────────────────
    task check;
        input [255:0] test_name;
        input [31:0]  got;
        input [31:0]  expected;
        begin
            if (got === expected) begin
                $display("  PASS  %-35s | imm=0x%08h (%0d)",
                          test_name, got, $signed(got));
                pass = pass + 1;
            end else begin
                $display("  FAIL  %-35s | got=0x%08h expected=0x%08h",
                          test_name, got, expected);
                fail = fail + 1;
            end
        end
    endtask
 
    // ── helper: build I-type instruction ─────────────────────
    // I-type: | imm[11:0] | rs1 | funct3 | rd | opcode |
    //           [31:20]    [19:15] [14:12] [11:7] [6:0]
    function [31:0] make_itype;
        input [11:0] imm12;   // 12-bit immediate
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            make_itype = { imm12, rs1, funct3, rd, opcode };
        end
    endfunction
 
    // ── helper: build S-type instruction ─────────────────────
    // S-type: | imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode |
    function [31:0] make_stype;
        input [11:0] imm12;
        input [4:0]  rs2, rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;
        begin
            make_stype = { imm12[11:5], rs2, rs1, funct3,
                           imm12[4:0], opcode };
        end
    endfunction
 
    // ── helper: build B-type instruction ─────────────────────
    // B-type: |imm[12]|imm[10:5]| rs2 | rs1 |f3|imm[4:1]|imm[11]|opcode|
    function [31:0] make_btype;
        input [12:0] imm13;  // 13-bit immediate (bit0 always 0)
        input [4:0]  rs2, rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;
        begin
            make_btype = { imm13[12], imm13[10:5], rs2, rs1, funct3,
                           imm13[4:1], imm13[11], opcode };
        end
    endfunction
 
    // ── helper: build U-type instruction ─────────────────────
    // U-type: | imm[31:12] | rd | opcode |
    function [31:0] make_utype;
        input [19:0] imm20;  // upper 20 bits
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            make_utype = { imm20, rd, opcode };
        end
    endfunction
 
    // ── helper: build J-type instruction ─────────────────────
    // J-type: |imm[20]|imm[10:1]|imm[11]|imm[19:12]| rd | opcode |
    function [31:0] make_jtype;
        input [20:0] imm21;  // 21-bit immediate (bit0 always 0)
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            make_jtype = { imm21[20], imm21[10:1], imm21[11],
                           imm21[19:12], rd, opcode };
        end
    endfunction
 
    // ── main test sequence ────────────────────────────────────
    initial begin
        $display("========================================");
        $display("  imm_ext Testbench");
        $display("  Tests all 5 immediate formats");
        $display("========================================");
 
        // ════════════════════════════════════════════
        // I-TYPE TESTS
        // opcode = 0010011 (ADDI, ANDI, ORI etc.)
        // imm = sign_extend(instr[31:20])
        // ════════════════════════════════════════════
        $display("\n-- I-type (ADDI / LW / JALR) --");
 
        // Test 1: ADDI x10, x0, 5  →  imm = 5
        // Encoding: imm=0x005, rs1=0, funct3=000, rd=10, opcode=0010011
        instr = make_itype(12'h005, 5'd0, 3'b000, 5'd10, 7'b0010011);
        #10;
        check("I-type: imm=+5", imm, 32'd5);
 
        // Test 2: ADDI x10, x0, -1  →  imm = 0xFFFFFFFF (-1 sign extended)
        // 12-bit -1 = 0xFFF
        instr = make_itype(12'hFFF, 5'd0, 3'b000, 5'd10, 7'b0010011);
        #10;
        check("I-type: imm=-1 (sign extend)", imm, 32'hFFFFFFFF);
 
        // Test 3: ADDI x0, x0, -2048  →  imm = 0xFFFFF800 (most negative 12-bit)
        // 12-bit most negative = 0x800 = 1000_0000_0000
        instr = make_itype(12'h800, 5'd0, 3'b000, 5'd0, 7'b0010011);
        #10;
        check("I-type: imm=-2048 (min)", imm, 32'hFFFFF800);
 
        // Test 4: ADDI x0, x0, 2047  →  imm = 2047 (max positive 12-bit)
        // 12-bit max positive = 0x7FF
        instr = make_itype(12'h7FF, 5'd0, 3'b000, 5'd0, 7'b0010011);
        #10;
        check("I-type: imm=+2047 (max)", imm, 32'd2047);
 
        // Test 5: LW x10, 4(x5)  →  imm = 4
        // opcode = 0000011 (LOAD)
        instr = make_itype(12'h004, 5'd5, 3'b010, 5'd10, 7'b0000011);
        #10;
        check("I-type LOAD: LW imm=4", imm, 32'd4);
 
        // Test 6: LW x10, -4(x5)  →  imm = -4 = 0xFFFFFFFC
        instr = make_itype(12'hFFC, 5'd5, 3'b010, 5'd10, 7'b0000011);
        #10;
        check("I-type LOAD: LW imm=-4", imm, 32'hFFFFFFFC);
 
        // ════════════════════════════════════════════
        // S-TYPE TESTS
        // opcode = 0100011 (SW, SH, SB)
        // imm = sign_extend({instr[31:25], instr[11:7]})
        // ════════════════════════════════════════════
        $display("\n-- S-type (SW / SH / SB) --");
 
        // Test 7: SW x10, 0(x5)  →  imm = 0
        instr = make_stype(12'h000, 5'd10, 5'd5, 3'b010, 7'b0100011);
        #10;
        check("S-type: SW imm=0", imm, 32'd0);
 
        // Test 8: SW x10, 8(x5)  →  imm = 8
        instr = make_stype(12'h008, 5'd10, 5'd5, 3'b010, 7'b0100011);
        #10;
        check("S-type: SW imm=8", imm, 32'd8);
 
        // Test 9: SW x10, -4(x5)  →  imm = -4 = 0xFFFFFFFC
        instr = make_stype(12'hFFC, 5'd10, 5'd5, 3'b010, 7'b0100011);
        #10;
        check("S-type: SW imm=-4 (sign extend)", imm, 32'hFFFFFFFC);
 
        // Test 10: SW x10, 2047(x0)  →  imm = 2047 (max positive)
        instr = make_stype(12'h7FF, 5'd10, 5'd0, 3'b010, 7'b0100011);
        #10;
        check("S-type: SW imm=+2047 (max)", imm, 32'd2047);
 
        // ════════════════════════════════════════════
        // B-TYPE TESTS
        // opcode = 1100011 (BEQ, BNE, BLT etc.)
        // imm = sign_extend({instr[31], instr[7], instr[30:25], instr[11:8], 0})
        // NOTE: bit 0 is always 0 (2-byte aligned branch targets)
        // ════════════════════════════════════════════
        $display("\n-- B-type (BEQ / BNE / BLT) --");
 
        // Test 11: BEQ x10, x11, +8  →  imm = 8
        // imm13 = 0000000001000 = 8
        instr = make_btype(13'h008, 5'd11, 5'd10, 3'b000, 7'b1100011);
        #10;
        check("B-type: BEQ imm=+8", imm, 32'd8);
 
        // Test 12: BEQ x0, x0, -8  →  imm = -8 = 0xFFFFFFF8
        // -8 in 13-bit = 1_1111_1111000
        instr = make_btype(13'h1FF8, 5'd0, 5'd0, 3'b000, 7'b1100011);
        #10;
        check("B-type: BEQ imm=-8 (backward branch)", imm, 32'hFFFFFFF8);
 
        // Test 13: BEQ imm=+4  (typical forward branch)
        instr = make_btype(13'h004, 5'd0, 5'd0, 3'b000, 7'b1100011);
        #10;
        check("B-type: BEQ imm=+4", imm, 32'd4);
 
        // Test 14: BNE imm=+20
        instr = make_btype(13'h014, 5'd1, 5'd2, 3'b001, 7'b1100011);
        #10;
        check("B-type: BNE imm=+20", imm, 32'd20);
 
        // ════════════════════════════════════════════
        // U-TYPE TESTS
        // opcode = 0110111 (LUI) or 0010111 (AUIPC)
        // imm = {instr[31:12], 12'b0}
        // Upper 20 bits of result = upper 20 bits of instruction
        // Lower 12 bits always 0
        // ════════════════════════════════════════════
        $display("\n-- U-type (LUI / AUIPC) --");
 
        // Test 15: LUI x10, 0x12345  →  imm = 0x12345000
        instr = make_utype(20'h12345, 5'd10, 7'b0110111);
        #10;
        check("U-type LUI: 0x12345", imm, 32'h12345000);
 
        // Test 16: LUI x0, 1  →  imm = 0x00001000
        instr = make_utype(20'h00001, 5'd0, 7'b0110111);
        #10;
        check("U-type LUI: 0x1", imm, 32'h00001000);
 
        // Test 17: AUIPC x10, 0xFFFFF  →  imm = 0xFFFFF000
        instr = make_utype(20'hFFFFF, 5'd10, 7'b0010111);
        #10;
        check("U-type AUIPC: 0xFFFFF", imm, 32'hFFFFF000);
 
        // Test 18: LUI x10, 0  →  imm = 0
        instr = make_utype(20'h00000, 5'd10, 7'b0110111);
        #10;
        check("U-type LUI: 0", imm, 32'h00000000);
 
        // ════════════════════════════════════════════
        // J-TYPE TESTS
        // opcode = 1101111 (JAL)
        // imm = sign_extend({instr[31], instr[19:12], instr[20], instr[30:21], 0})
        // NOTE: bit 0 always 0 (jump targets 2-byte aligned)
        // ════════════════════════════════════════════
        $display("\n-- J-type (JAL) --");
 
        // Test 19: JAL x1, +4  →  imm = 4
        instr = make_jtype(21'h00004, 5'd1, 7'b1101111);
        #10;
        check("J-type JAL: imm=+4", imm, 32'd4);
 
        // Test 20: JAL x0, +100  →  imm = 100
        instr = make_jtype(21'h00064, 5'd0, 7'b1101111);
        #10;
        check("J-type JAL: imm=+100", imm, 32'd100);
 
        // Test 21: JAL x1, -4  →  imm = -4 = 0xFFFFFFFC
        // -4 in 21-bit = 1_1111_1111_1111_1111_100
        instr = make_jtype(21'h1FFFFC, 5'd1, 7'b1101111);
        #10;
        check("J-type JAL: imm=-4 (backward jump)", imm, 32'hFFFFFFFC);
 
        // Test 22: JAL x0, +1048572 (near max positive J-type)
        // max positive 21-bit = 0xFFFFE = 1048574
        instr = make_jtype(21'h0FFFE, 5'd0, 7'b1101111);
        #10;
        check("J-type JAL: imm=+65534", imm, 32'hFFFE);
 
        // ════════════════════════════════════════════
        // R-TYPE and CUSTOM-0 - should return 0
        // These instruction types have no immediate field
        // ════════════════════════════════════════════
        $display("\n-- R-type and CUSTOM-0 (no immediate → 0) --");
 
        // Test 23: R-type (ADD x10, x11, x12)
        // opcode = 0110011, no immediate field
        instr = 32'h00C58533; // ADD x10, x11, x12
        #10;
        check("R-type: imm=0 (no immediate)", imm, 32'h0);
 
        // Test 24: CUSTOM-0 (XMAC instruction)
        // opcode = 0001011
        instr = 32'h60B5068B; // XMAC x13, x10, x11, x12
        #10;
        check("CUSTOM-0 XMAC: imm=0", imm, 32'h0);
 
        // ════════════════════════════════════════════
        // REAL PROGRAM ENCODING VERIFICATION
        // These are actual hex encodings you will put
        // in your program.hex file - verify they decode correctly
        // ════════════════════════════════════════════
        $display("\n-- Real instruction encoding verification --");
 
        // ADDI x10, x0, 5  =  0x00500513
        instr = 32'h00500513;
        #10;
        check("0x00500513 ADDI x10,x0,5", imm, 32'd5);
 
        // ADDI x11, x0, 3  =  0x00300593
        instr = 32'h00300593;
        #10;
        check("0x00300593 ADDI x11,x0,3", imm, 32'd3);
 
        // LW x10, 0(x0)  =  0x00002503
        instr = 32'h00002503;
        #10;
        check("0x00002503 LW x10,0(x0)", imm, 32'd0);
 
        // LW x10, 4(x5)  =  0x00428503
        instr = 32'h00428503;
        #10;
        check("0x00428503 LW x10,4(x5)", imm, 32'd4);
 
        // SW x10, 0(x0)  =  0x00A02023
        instr = 32'h00A02023;
        #10;
        check("0x00A02023 SW x10,0(x0)", imm, 32'd0);
 
        // BEQ x10, x11, +8  =  0x00B50463
        instr = 32'h00B50463;
        #10;
        check("0x00B50463 BEQ +8", imm, 32'd8);
 
        // ── FINAL SUMMARY ─────────────────────────────────────
        $display("\n========================================");
        $display("  PASSED : %0d", pass);
        $display("  FAILED : %0d", fail);
        $display("  TOTAL  : %0d", pass + fail);
        if (fail == 0)
            $display("  ALL TESTS PASSED - imm_ext OK!");
        else begin
            $display("  SOME TESTS FAILED.");
            $display("  Most common cause:");
            $display("  - Wrong bit positions in case branch");
            $display("  - Missing opcode in case (falls to default)");
            $display("  - Replication count wrong in sign extension");
        end
        $display("========================================");
        $finish;
    end
 
endmodule