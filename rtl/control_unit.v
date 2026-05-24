module control_unit (
    // ── inputs from instruction fields ───────────────────────
    input  wire [6:0]  opcode,   // instr[6:0]   - instruction class
    input  wire [2:0]  funct3,   // instr[14:12] - sub-operation
    input  wire [6:0]  funct7,   // instr[31:25] - further qualifier
 
    // ── outputs: control signals ──────────────────────────────
    output reg         reg_write,  // 1 = write result to register rd
    output reg         mem_read,   // 1 = read from data memory (LW)
    output reg         mem_write,  // 1 = write to data memory (SW)
    output reg         branch,     // 1 = branch instruction
    output reg         alu_src,    // 0 = use rs2,  1 = use immediate
    output reg         mem_to_reg, // 0 = ALU result, 1 = memory data
    output reg         xmac_en,    // 1 = use XMAC unit (custom-0)
    output reg  [3:0]  alu_op      // ALU operation selector
);
 
    // ── OPCODE localparams ────────────────────────────────────
    // These are the 7-bit opcode values for each instruction class.
    // Defined here so the case statement is readable.
    localparam OPCODE_RTYPE   = 7'b0110011; // ADD SUB AND OR XOR SLL SRL SRA SLT SLTU
    localparam OPCODE_ITYPE   = 7'b0010011; // ADDI ANDI ORI XORI SLLI SRLI SRAI SLTI
    localparam OPCODE_LOAD    = 7'b0000011; // LW LH LB LHU LBU
    localparam OPCODE_STORE   = 7'b0100011; // SW SH SB
    localparam OPCODE_BRANCH  = 7'b1100011; // BEQ BNE BLT BGE BLTU BGEU
    localparam OPCODE_JAL     = 7'b1101111; // JAL
    localparam OPCODE_JALR    = 7'b1100111; // JALR
    localparam OPCODE_LUI     = 7'b0110111; // LUI
    localparam OPCODE_AUIPC   = 7'b0010111; // AUIPC
    localparam OPCODE_CUSTOM0 = 7'b0001011; // XMAC (custom-0 space)
 
    // ── ALU operation localparams ─────────────────────────────
    // 4-bit encoding: {funct7[5], funct3}
    // This is how the control unit maps instruction type to ALU op.
    localparam ALU_ADD  = 4'b0000; // funct7[5]=0, funct3=000 → ADD / ADDI
    localparam ALU_SUB  = 4'b1000; // funct7[5]=1, funct3=000 → SUB
    localparam ALU_SLL  = 4'b0001; // funct3=001 → Shift Left Logical
    localparam ALU_SLT  = 4'b0010; // funct3=010 → Set Less Than (signed)
    localparam ALU_SLTU = 4'b0011; // funct3=011 → Set Less Than Unsigned
    localparam ALU_XOR  = 4'b0100; // funct3=100 → XOR
    localparam ALU_SRL  = 4'b0101; // funct7[5]=0, funct3=101 → Shift Right Logical
    localparam ALU_SRA  = 4'b1101; // funct7[5]=1, funct3=101 → Shift Right Arithmetic
    localparam ALU_OR   = 4'b0110; // funct3=110 → OR
    localparam ALU_AND  = 4'b0111; // funct3=111 → AND
 
    // ── combinational decode ──────────────────────────────────
    // CRITICAL: set ALL signals to safe defaults first.
    // If ANY signal is missing from any case branch,
    // Verilog infers a LATCH - unintended hardware that holds
    // state between clock cycles. Defaults prevent this.
    always @(*) begin
 
        // ── SAFE DEFAULTS (all signals off) ──────────────────
        reg_write  = 1'b0;  // don't write any register
        mem_read   = 1'b0;  // don't read memory
        mem_write  = 1'b0;  // don't write memory
        branch     = 1'b0;  // not a branch
        alu_src    = 1'b0;  // use rs2 (not immediate)
        mem_to_reg = 1'b0;  // use ALU result (not memory data)
        xmac_en    = 1'b0;  // use ALU (not XMAC unit)
        alu_op     = ALU_ADD; // default to ADD (safe for address calc)
 
        // ── INSTRUCTION DECODE ────────────────────────────────
        case (opcode)
 
            // ── R-TYPE ────────────────────────────────────────
            // Instructions: ADD SUB AND OR XOR SLL SRL SRA SLT SLTU
            // - Two register operands (rs1, rs2)
            // - Result written to rd
            // - ALU op determined by {funct7[5], funct3}
            //   funct7[5]=0 → ADD, SLL, SLT, SLTU, XOR, SRL, OR, AND
            //   funct7[5]=1 → SUB, SRA (same funct3, different funct7)
            OPCODE_RTYPE: begin
                reg_write = 1'b1;                       // write result to rd
                alu_src   = 1'b0;                       // use rs2 (not imm)
                alu_op    = {funct7[5], funct3};         // encodes all 10 R-ops
                // mem_read=0, mem_write=0, branch=0 (already defaulted)
            end
 
            // ── I-TYPE ALU ────────────────────────────────────
            // Instructions: ADDI ANDI ORI XORI SLTI SLTIU SLLI SRLI SRAI
            // - One register (rs1) + sign-extended immediate
            // - Result written to rd
            // - Special case: SRAI uses funct7[5] to distinguish from SRLI
            //   Both have funct3=101. SRLI: funct7[5]=0. SRAI: funct7[5]=1.
            OPCODE_ITYPE: begin
                reg_write = 1'b1;                       // write result to rd
                alu_src   = 1'b1;                       // use immediate
                // For shifts (funct3=101): include funct7[5] to get SRL vs SRA
                // For all others: funct7[5]=0 always (no ambiguity)
                alu_op    = (funct3 == 3'b101) ?
                             {funct7[5], funct3}  :     // SRLI or SRAI
                             {1'b0, funct3};             // all other I-type
            end
 
            // ── LOAD ──────────────────────────────────────────
            // Instructions: LW, LH, LB, LHU, LBU
            // - Address = rs1 + sign_extended_immediate
            // - Data read from memory written to rd
            // (we only implement LW fully - extend for LH/LB later)
            OPCODE_LOAD: begin
                reg_write  = 1'b1;    // write loaded data to rd
                mem_read   = 1'b1;    // read from data memory
                alu_src    = 1'b1;    // address = rs1 + immediate
                mem_to_reg = 1'b1;    // write memory data (not ALU result)
                alu_op     = ALU_ADD; // address calculation: rs1 + imm
            end
 
            // ── STORE ─────────────────────────────────────────
            // Instructions: SW, SH, SB
            // - Address = rs1 + sign_extended_immediate
            // - Data from rs2 written to memory
            // - NO register write (stores go to memory, not rd)
            OPCODE_STORE: begin
                mem_write  = 1'b1;    // write to data memory
                alu_src    = 1'b1;    // address = rs1 + immediate
                alu_op     = ALU_ADD; // address calculation: rs1 + imm
                // reg_write=0: SW writes memory, not a register
            end
 
            // ── BRANCH ────────────────────────────────────────
            // Instructions: BEQ, BNE, BLT, BGE, BLTU, BGEU
            // - Compare rs1 and rs2
            // - If condition true: PC = PC + B-type immediate
            // - ALU computes rs1 - rs2 for comparison
            // - branch_taken = branch & (condition based on funct3)
            // (in ex_stage - for now only BEQ is fully wired)
            OPCODE_BRANCH: begin
                branch  = 1'b1;    // signal this is a branch
                alu_op  = ALU_SUB; // subtract rs1-rs2 for comparison
                alu_src = 1'b0;    // compare against rs2 (not immediate)
                // reg_write=0: branches don't write a register
            end
 
            // ── JAL ───────────────────────────────────────────
            // Jump And Link
            // - PC = PC + J-type immediate (jump target)
            // - rd = PC + 4 (return address)
            // (simplified: treat as reg_write for now, extend later)
            OPCODE_JAL: begin
                reg_write = 1'b1;    // write return address to rd
                alu_src   = 1'b1;    // use immediate
                alu_op    = ALU_ADD; // target = PC + imm (in ex_stage)
            end
 
            // ── JALR ──────────────────────────────────────────
            // Jump And Link Register
            // - PC = (rs1 + I-type immediate) & ~1
            // - rd = PC + 4
            OPCODE_JALR: begin
                reg_write = 1'b1;    // write return address to rd
                alu_src   = 1'b1;    // use immediate
                alu_op    = ALU_ADD; // target = rs1 + imm
            end
 
            // ── LUI ───────────────────────────────────────────
            // Load Upper Immediate
            // - rd = U-type immediate (upper 20 bits, lower 12 = 0)
            // - Effectively: rd = 0 + imm (ALU adds 0 to immediate)
            OPCODE_LUI: begin
                reg_write = 1'b1;    // write result to rd
                alu_src   = 1'b1;    // use immediate (upper 20 bits)
                alu_op    = ALU_ADD; // rd = x0 + imm
                // Note: rs1 reads x0 (which is 0) + immediate
            end
 
            // ── AUIPC ─────────────────────────────────────────
            // Add Upper Immediate to PC
            // - rd = PC + U-type immediate
            OPCODE_AUIPC: begin
                reg_write = 1'b1;    // write result to rd
                alu_src   = 1'b1;    // use immediate
                alu_op    = ALU_ADD; // rd = PC + imm (ex_stage uses pc not rs1)
            end
 
            // ── CUSTOM-0 : XMAC ───────────────────────────────
            // Your novel instruction: rd = rs1 * rs2 + rs3
            // - Uses custom-0 opcode space (0x0B = 7'b0001011)
            // - R4-type encoding (rs3 in bits [31:27])
            // - xmac_en=1 tells ex_stage to use xmac_unit output
            //   instead of ALU output
            // - All memory and branch signals stay 0
            OPCODE_CUSTOM0: begin
                reg_write = 1'b1;  // write XMAC result to rd
                xmac_en   = 1'b1;  // select XMAC unit output in EX
                alu_src   = 1'b0;  // XMAC always uses registers (no imm)
                // alu_op is irrelevant when xmac_en=1
                // (ALU still runs but its output is muxed away)
            end
 
            // ── DEFAULT ───────────────────────────────────────
            // Unknown or unimplemented opcode.
            // All signals already at safe defaults (0).
            // The instruction passes through as a NOP.
            default: begin
                // nothing to do - defaults handle it
            end
 
        endcase
    end
 
endmodule