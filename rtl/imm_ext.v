module imm_ext (
    input  wire [31:0] instr,   // full 32-bit instruction word
    output reg  [31:0] imm      // sign-extended 32-bit immediate
);
 
    // ── opcode localparams ────────────────────────────────────
    // Used only to select the correct immediate format.
    // The opcode tells us WHICH format the immediate is in.
    localparam OPCODE_ITYPE  = 7'b0010011; // ADDI, ANDI, ORI, XORI, SLTI
    localparam OPCODE_LOAD   = 7'b0000011; // LW, LH, LB
    localparam OPCODE_JALR   = 7'b1100111; // JALR  (also I-type immediate)
    localparam OPCODE_STORE  = 7'b0100011; // SW, SH, SB  (S-type)
    localparam OPCODE_BRANCH = 7'b1100011; // BEQ,BNE,BLT,BGE (B-type)
    localparam OPCODE_LUI    = 7'b0110111; // LUI   (U-type)
    localparam OPCODE_AUIPC  = 7'b0010111; // AUIPC (U-type)
    localparam OPCODE_JAL    = 7'b1101111; // JAL   (J-type)
    // R-type (0110011) and CUSTOM0 (0001011) have no immediate → return 0
 
    // ── extract opcode from instruction ──────────────────────
    wire [6:0] opcode = instr[6:0];
 
    // ── combinational immediate selection ─────────────────────
    // always @(*) = re-evaluate whenever instr changes
    // This is purely combinational - no clock involved
    always @(*) begin
        case (opcode)
 
            // ── I-TYPE ────────────────────────────────────────
            // Used by: ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI
            //          LW, LH, LB, LBU, LHU, JALR
            // Immediate bits: [31:20]  (12 bits)
            // Sign bit: instr[31]
            // Format:  imm[11:0] = instr[31:20]
            OPCODE_ITYPE,
            OPCODE_LOAD,
            OPCODE_JALR: begin
                imm = { {20{instr[31]}},   // sign extend: repeat bit31 20 times
                         instr[31:20] };    // 12-bit immediate
            end
 
            // ── S-TYPE ────────────────────────────────────────
            // Used by: SW, SH, SB
            // Immediate is SPLIT across two fields to keep rs2 at [24:20]
            // Upper 7 bits: instr[31:25]
            // Lower 5 bits: instr[11:7]
            // Reassembled: {instr[31:25], instr[11:7]}
            OPCODE_STORE: begin
                imm = { {20{instr[31]}},   // sign extend
                         instr[31:25],      // imm[11:5]
                         instr[11:7] };     // imm[4:0]
            end
 
            // ── B-TYPE ────────────────────────────────────────
            // Used by: BEQ, BNE, BLT, BGE, BLTU, BGEU
            // Immediate is SCRAMBLED - to keep rs1/rs2/rd in fixed positions
            // Bit 12 (sign):  instr[31]
            // Bit 11:         instr[7]
            // Bits 10:5:      instr[30:25]
            // Bits 4:1:       instr[11:8]
            // Bit 0:          always 0 (branch targets are 2-byte aligned)
            OPCODE_BRANCH: begin
                imm = { {19{instr[31]}},   // sign extend
                         instr[31],         // imm[12]
                         instr[7],          // imm[11]
                         instr[30:25],      // imm[10:5]
                         instr[11:8],       // imm[4:1]
                         1'b0 };            // imm[0] = 0 always
            end
 
            // ── U-TYPE ────────────────────────────────────────
            // Used by: LUI, AUIPC
            // 20-bit immediate placed in the UPPER 20 bits of the result
            // Lower 12 bits are always zero
            // No sign extension needed - the immediate IS the upper bits
            OPCODE_LUI,
            OPCODE_AUIPC: begin
                imm = { instr[31:12],      // imm[31:12] - upper 20 bits
                         12'b0 };           // imm[11:0]  - lower 12 bits = 0
            end
 
            // ── J-TYPE ────────────────────────────────────────
            // Used by: JAL
            // Also SCRAMBLED like B-type
            // Bit 20 (sign): instr[31]
            // Bits 19:12:    instr[19:12]  ← note: not contiguous in instruction
            // Bit 11:        instr[20]
            // Bits 10:1:     instr[30:21]
            // Bit 0:         always 0 (jump targets are 2-byte aligned)
            OPCODE_JAL: begin
                imm = { {11{instr[31]}},   // sign extend
                         instr[31],         // imm[20]
                         instr[19:12],      // imm[19:12]
                         instr[20],         // imm[11]
                         instr[30:21],      // imm[10:1]
                         1'b0 };            // imm[0] = 0 always
            end
 
            // ── R-TYPE and CUSTOM-0 (XMAC) ────────────────────
            // These instruction types have NO immediate field.
            // Return 0 - the EX stage will ignore this value anyway.
            default: begin
                imm = 32'b0;
            end
 
        endcase
    end 
 
endmodule