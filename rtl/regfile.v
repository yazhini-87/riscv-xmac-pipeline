module regfile (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [4:0]  rs1, rs2, rs3,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2,
    output wire [31:0] rd3
);
    reg [31:0] regs [0:31];
    

    assign rd1 = (rs1 == 5'b0) ? 32'b0 : regs[rs1];
    assign rd2 = (rs2 == 5'b0) ? 32'b0 : regs[rs2];
    assign rd3 = (rs3 == 5'b0) ? 32'b0 : regs[rs3];

// In regfile.v - just add initial block, keep everything else:
integer i;
initial begin
    for (i = 0; i < 32; i = i + 1)
        regs[i] = 32'b0;
end

// Keep existing always block unchanged:
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] <= 32'b0;
    end else if (we && rd != 5'b0) begin
        regs[rd] <= wd;
    end
    end

endmodule