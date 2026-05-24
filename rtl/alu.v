module alu (
    input  wire [31:0] a, b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] result,
    output wire        zero      // used for BEQ condition
);
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
    assign zero = (result == 32'b0);
 
    always @(*) begin
        case (alu_op)
            ALU_ADD:  result = a + b;
            ALU_SUB:  result = a - b;
            ALU_AND:  result = a & b;
            ALU_OR:   result = a | b;
            ALU_XOR:  result = a ^ b;
            ALU_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU: result = (a < b)                   ? 32'd1 : 32'd0;
            ALU_SLL:  result = a << b[4:0];
            ALU_SRL:  result = a >> b[4:0];
            ALU_SRA:  result = $signed(a) >>> b[4:0];
            default:   result = 32'b0;
        endcase
    end
 
endmodule