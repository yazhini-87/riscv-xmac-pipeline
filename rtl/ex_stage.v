`timescale 1ns/1ps

module ex_stage (
    input  wire [31:0] pc,
    input  wire [31:0] rs1_data, rs2_data, rs3_data,
    input  wire [31:0] imm_ext,
    input  wire [3:0]  alu_op,
    input  wire        alu_src,
    input  wire        branch,
    input  wire        xmac_en,        
    // forwarding inputs
    input  wire [1:0]  forward_a,
    input  wire [1:0]  forward_b,
    input  wire [1:0]  forward_c,
    input  wire [31:0] ex_mem_result,
    input  wire [31:0] mem_wb_result,
    input  wire [31:0] wb_result,

    // outputs
    output wire [31:0] alu_result,
    output wire [31:0] rs2_forwarded,
    output wire [31:0] branch_target,
    output wire        branch_taken
);
    // ── forwarding muxes ──────────────────────────────────────
    wire [31:0] op_a =
        (forward_a == 2'b10) ? ex_mem_result :
        (forward_a == 2'b01) ? mem_wb_result :
         (forward_a == 2'b11) ? wb_result :    // ← ADD WB case
                                rs1_data;

                  
       

    wire [31:0] op_b_reg =
        (forward_b == 2'b10) ? ex_mem_result :
        (forward_b == 2'b01) ? mem_wb_result :
        (forward_b == 2'b11) ? wb_result : 
                                rs2_data;

    wire [31:0] op_c =
        (forward_c == 2'b10) ? ex_mem_result :
        (forward_c == 2'b01) ? mem_wb_result :
        (forward_c == 2'b11) ? wb_result :  
                                rs3_data;

    // rs2 after forwarding - passed to MEM stage for SW
    assign rs2_forwarded = op_b_reg;

    // ALU second operand: register or immediate
    wire [31:0] op_b = alu_src ? imm_ext : op_b_reg;

    // ── ALU instantiation ─────────────────────────────────────
    wire [31:0] alu_out;
    wire        alu_zero;

    alu u_alu (
        .a      (op_a),
        .b      (op_b),
        .alu_op (alu_op),
        .result (alu_out),
        .zero   (alu_zero)
    );

    // ── XMAC instantiation ────────────────────────────────────
    wire [31:0] xmac_out;

    xmac_unit u_xmac (
        .rs1    (op_a),
        .rs2    (op_b_reg),
        .rs3    (op_c),
        .result (xmac_out)
    );

    // ── result mux: ALU or XMAC ──────────────────────────────
    assign alu_result  = xmac_en ? xmac_out : alu_out;

    // ── branch logic ─────────────────────────────────────────
    assign branch_target = pc + imm_ext;
    assign branch_taken  = branch & alu_zero;

endmodule