module forwarding_unit (
    // Source registers in EX stage (from ID/EX register)
    input  wire [4:0]  id_ex_rs1,
    input  wire [4:0]  id_ex_rs2,
    input  wire [4:0]  id_ex_rs3,
    input  wire        id_ex_xmac_en,

    // EX/MEM pipeline register
    input  wire [4:0]  ex_mem_rd,
    input  wire        ex_mem_reg_write,

    // MEM/WB pipeline register
    input  wire [4:0]  mem_wb_rd,
    input  wire        mem_wb_reg_write,

    // WB stage (new) ──────────────────────────────────────────
    input  wire [4:0]  wb_rd,
    input  wire        wb_reg_write,

    // Forwarding select outputs
    output reg  [1:0]  forward_a,
    output reg  [1:0]  forward_b,
    output reg  [1:0]  forward_c
);
    // ── Local Parameters ─────────────────────────────────────
    localparam FWD_REG   = 2'b00;  // use register file
    localparam FWD_MEMWB = 2'b01;  // forward from MEM/WB
    localparam FWD_EXMEM = 2'b10;  // forward from EX/MEM
    localparam FWD_WB    = 2'b11;  // forward from WB stage ← NEW

    // ── forward_a (rs1) ──────────────────────────────────────
    // Priority: EX/MEM > MEM/WB > WB > regfile
    always @(*) begin
        if (ex_mem_reg_write &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs1))
            forward_a = FWD_EXMEM;         // highest priority
        else if (mem_wb_reg_write &&
            (mem_wb_rd != 5'd0) &&
            (mem_wb_rd == id_ex_rs1))
            forward_a = FWD_MEMWB;
        else if (wb_reg_write &&            // ← NEW
            (wb_rd != 5'd0) &&
            (wb_rd == id_ex_rs1))
            forward_a = FWD_WB;            // WB stage forward
        else
            forward_a = FWD_REG;
    end

    // ── forward_b (rs2) ──────────────────────────────────────
    always @(*) begin
        if (ex_mem_reg_write &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs2))
            forward_b = FWD_EXMEM;
        else if (mem_wb_reg_write &&
            (mem_wb_rd != 5'd0) &&
            (mem_wb_rd == id_ex_rs2))
            forward_b = FWD_MEMWB;
        else if (wb_reg_write &&            // ← NEW
            (wb_rd != 5'd0) &&
            (wb_rd == id_ex_rs2))
            forward_b = FWD_WB;
        else
            forward_b = FWD_REG;
    end

    // ── forward_c (rs3 - XMAC only) ──────────────────────────
    always @(*) begin
        if (!id_ex_xmac_en)
            forward_c = FWD_REG;
        else if (ex_mem_reg_write &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs3))
            forward_c = FWD_EXMEM;
        else if (mem_wb_reg_write &&
            (mem_wb_rd != 5'd0) &&
            (mem_wb_rd == id_ex_rs3))
            forward_c = FWD_MEMWB;
        else if (wb_reg_write &&            // ← NEW
            (wb_rd != 5'd0) &&
            (wb_rd == id_ex_rs3))
            forward_c = FWD_WB;
        else
            forward_c = FWD_REG;
    end

endmodule