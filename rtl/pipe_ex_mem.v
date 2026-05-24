
module pipe_ex_mem (
    input  wire        clk,
    input  wire        rst,
 
    // ── Data inputs (from EX stage) ──────────────────────────
    input  wire [31:0] ex_alu_result,   // ALU or XMAC result
    input  wire [31:0] ex_rs2_data,     // forwarded rs2 (SW store data)
    input  wire [4:0]  ex_rd,           // destination register index
 
    // ── Control inputs (from ID/EX register) ─────────────────
    input  wire        ex_reg_write,    // 1 = write result to register
    input  wire        ex_mem_read,     // 1 = LW (read from DMEM)
    input  wire        ex_mem_write,    // 1 = SW (write to DMEM)
    input  wire        ex_mem_to_reg,   // 0 = ALU result, 1 = memory data
 
    // ── Data outputs (to MEM stage) ──────────────────────────
    output reg  [31:0] mem_alu_result,  // address or computation result
    output reg  [31:0] mem_rs2_data,    // store data for SW
    output reg  [4:0]  mem_rd,          // destination register index
 
    // ── Control outputs (to MEM stage and forwarding unit) ───
    output reg         mem_reg_write,   // forwarding unit checks this
    output reg         mem_mem_read,    // MEM stage: read DMEM
    output reg         mem_mem_write,   // MEM stage: write DMEM
    output reg         mem_mem_to_reg   // WB mux select
);
 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // ── synchronous reset - clear everything ─────────
            mem_alu_result <= 32'b0;
            mem_rs2_data   <= 32'b0;
            mem_rd         <= 5'b0;
            mem_reg_write  <= 1'b0;
            mem_mem_read   <= 1'b0;
            mem_mem_write  <= 1'b0;
            mem_mem_to_reg <= 1'b0;
        end else begin
            // ── latch EX outputs for MEM stage ───────────────
            mem_alu_result <= ex_alu_result;
            mem_rs2_data   <= ex_rs2_data;
            mem_rd         <= ex_rd;
            mem_reg_write  <= ex_reg_write;
            mem_mem_read   <= ex_mem_read;
            mem_mem_write  <= ex_mem_write;
            mem_mem_to_reg <= ex_mem_to_reg;
        end
    end
 
endmodule