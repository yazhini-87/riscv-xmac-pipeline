 module pipe_id_ex (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,
    input  wire        stall,        // ← ADD THIS
    // Data inputs
    input  wire [31:0] id_pc,
    input  wire [31:0] id_rs1_data, id_rs2_data, id_rs3_data,
    input  wire [31:0] id_imm_ext,
    input  wire [4:0]  id_rs1, id_rs2, id_rs3, id_rd,
    // Control inputs
    input  wire        id_reg_write, id_mem_read, id_mem_write,
    input  wire        id_branch, id_alu_src, id_mem_to_reg,
    input  wire        id_xmac_en,
    input  wire [3:0]  id_alu_op,
    // Data outputs
    output reg  [31:0] ex_pc,
    output reg  [31:0] ex_rs1_data, ex_rs2_data, ex_rs3_data,
    output reg  [31:0] ex_imm_ext,
    output reg  [4:0]  ex_rs1, ex_rs2, ex_rs3, ex_rd,
    // Control outputs
    output reg         ex_reg_write, ex_mem_read, ex_mem_write,
    output reg         ex_branch, ex_alu_src, ex_mem_to_reg,
    output reg         ex_xmac_en,
    output reg  [3:0]  ex_alu_op
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            // ── Insert bubble (NOP) ──────────────────────────
            ex_pc        <= 32'b0;
            ex_rs1_data  <= 32'b0; ex_rs2_data  <= 32'b0;
            ex_rs3_data  <= 32'b0;
            ex_imm_ext   <= 32'b0;
            ex_rs1       <= 5'b0;  ex_rs2       <= 5'b0;
            ex_rs3       <= 5'b0;  ex_rd        <= 5'b0;
            ex_reg_write <= 1'b0;  ex_mem_read  <= 1'b0;
            ex_mem_write <= 1'b0;  ex_branch    <= 1'b0;
            ex_alu_src   <= 1'b0;  ex_mem_to_reg<= 1'b0;
            ex_xmac_en   <= 1'b0;  ex_alu_op    <= 4'b0;
        end else if (!stall) begin  // ← CHANGED from else to else if (!stall)
            // ── Normal: latch inputs ─────────────────────────
            ex_pc        <= id_pc;
            ex_rs1_data  <= id_rs1_data; ex_rs2_data  <= id_rs2_data;
            ex_rs3_data  <= id_rs3_data;
            ex_imm_ext   <= id_imm_ext;
            ex_rs1       <= id_rs1;      ex_rs2       <= id_rs2;
            ex_rs3       <= id_rs3;      ex_rd        <= id_rd;
            ex_reg_write <= id_reg_write; ex_mem_read  <= id_mem_read;
            ex_mem_write <= id_mem_write; ex_branch    <= id_branch;
            ex_alu_src   <= id_alu_src;   ex_mem_to_reg<= id_mem_to_reg;
            ex_xmac_en   <= id_xmac_en;   ex_alu_op   <= id_alu_op;
        end
        // stall: hold all values implicitly ✅
    end

endmodule