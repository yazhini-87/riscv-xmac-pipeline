module hazard_unit (
    input  wire        id_ex_mem_read, // EX stage: is it a LOAD?
    input  wire [4:0]  id_ex_rd,       // EX stage: destination register
    input  wire [4:0]  if_id_rs1,      // ID stage: source register 1
    input  wire [4:0]  if_id_rs2,      // ID stage: source register 2
    input  wire        branch_taken,   // EX stage: branch resolved taken
    output wire        stall,          // stall IF and IF/ID
    output wire        flush_id,       // flush IF/ID (branch)
    output wire        flush_ex        // flush ID/EX (load-use bubble)
);
    // Load-use hazard: EX is a LOAD and rd matches ID's rs1 or rs2
    wire load_use_hazard =
        id_ex_mem_read &&
        (id_ex_rd != 5'b0) &&           // don't stall for x0
        ((id_ex_rd == if_id_rs1) ||
         (id_ex_rd == if_id_rs2));
 
    assign stall    = load_use_hazard;
    assign flush_ex = load_use_hazard;  // insert bubble in ID/EX
    assign flush_id = branch_taken;     // flush wrong-path instruction
 
endmodule