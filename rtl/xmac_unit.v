`timescale 1ns/1ps

module xmac_unit (
    input  wire [31:0] rs1,   // multiplier
    input  wire [31:0] rs2,   // multiplicand  
    input  wire [31:0] rs3,   // accumulate input
    output wire [31:0] result // rd = rs1*rs2 + rs3
);
    // 64-bit intermediate prevents overflow
    // $signed ensures correct signed multiplication
    wire [63:0] product = $signed(rs1) * $signed(rs2);
    
    // Take lower 32 bits - matches RISC-V MUL behaviour
    assign result = product[31:0] + rs3;

endmodule