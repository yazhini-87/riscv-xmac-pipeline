module wb_stage (
    input  wire        mem_to_reg,
    input  wire [31:0] alu_result,
    input  wire [31:0] mem_read_data,
    output wire [31:0] wb_data
);
    // Mux: LW → memory data, everything else → ALU/XMAC result
    assign wb_data = mem_to_reg ? mem_read_data : alu_result;
 
    // NOTE: wb_data, wb_reg_write, and wb_rd are routed back
    // to id_stage (regfile write port) in riscv_top.v
 
endmodule