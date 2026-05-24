module mem_stage (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);
    // ── Data memory (BRAM - separate from IMEM, Harvard arch) ─
    reg [31:0] dmem [0:4095];   // 4096 words = 16 KB
 
    // Synchronous write (SW)
    always @(posedge clk) begin
        if (mem_write)
            dmem[addr[13:2]] <= write_data;
    end
 
    // Combinational read (LW)
    // Returns 0 when mem_read=0 so MEM/WB gets a clean value
    assign read_data = mem_read ? dmem[addr[13:2]] : 32'b0;
 
endmodule
