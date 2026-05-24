module id_stage
                ( input wire clk,
                input wire rst, 
                  input wire [31:0] instr, // write-back port (from WB stage) 
                  input wire wb_reg_write, 
                  input wire [4:0] wb_rd, 
                  input wire [31:0] wb_data, // register indices (bit-field extraction) 
                  output wire [4:0] rs1, rs2, rs3, rd, // register read data 
                  output wire [31:0] rs1_data, rs2_data, rs3_data, 
                  output wire [31:0] imm_ext, // control signals 
                  output wire reg_write, mem_read, 
                  output wire mem_write, branch, 
                  output wire alu_src, mem_to_reg, xmac_en, 
                  output wire [3:0] alu_op ); // hardwired bit-field extraction 
                  
                  assign rs1 = instr[19:15]; 
                  assign rs2 = instr[24:20]; 
                  assign rs3 = instr[31:27]; // XMAC rs3 
                  assign rd = instr[11:7];
                  
                   // instantiate sub-modules 
                        regfile u_rf (.clk(clk), 
                                .we(wb_reg_write), 
                                .rs1(rs1), 
                                .rs2(rs2), 
                                .rs3(rs3), 
                                .rd(wb_rd), 
                                .wd(wb_data), 
                                .rd1(rs1_data), 
                                .rd2(rs2_data), 
                                .rd3(rs3_data)); 
                                
                        imm_ext u_imm (.instr(instr), 
                                 .imm(imm_ext)); 
                                 
                        control_unit u_cu (
                        .opcode    (instr[6:0]),
                        .funct3    (instr[14:12]),
                        .funct7    (instr[31:25]),
                        .reg_write (reg_write),
                        .mem_read  (mem_read),
                        .mem_write (mem_write),
                        .branch    (branch),
                        .alu_src   (alu_src),
                        .mem_to_reg(mem_to_reg),
                        .xmac_en   (xmac_en),
                        .alu_op    (alu_op));
                     endmodule