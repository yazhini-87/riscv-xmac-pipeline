module if_stage ( input wire clk, rst,
                     input wire stall, // from hazard unit 
                     input wire branch_taken, // from EX stage 
                     input wire [31:0] branch_target, // from EX stage 
                     output reg [31:0] pc, // current PC 
                     output wire [31:0] instr // fetched instruction
                      ); 
                      // 16 KB instruction memory 
                      reg [31:0] imem [0:255]; 
                      initial $readmemh("program.mem", imem); // combinational read - always outputs instr at current pc 
                      assign instr = imem[pc[13:2]]; // synchronous PC update 
                      
                      always @(posedge clk or posedge rst) 
                        begin 
                            if (rst) pc <= 32'b0; // reset → jump to address 0 
                            else if (!stall) begin if (branch_taken) pc <= branch_target; // branch taken → jump 
                            else pc <= pc + 32'd4; // normal → next instruction 
                        end // stall=1: no else → pc holds its value 
                      end 
                   endmodule
