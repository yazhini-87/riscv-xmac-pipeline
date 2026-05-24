module pipe_if_id (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire        flush,
    input  wire [31:0] if_pc,
    input  wire [31:0] if_instr,
    output reg  [31:0] id_pc,
    output reg  [31:0] id_instr
);
    // ── Local Parameter ──────────────────────────────────────
    localparam NOP = 32'h00000013;  // ADDI x0, x0, 0 (standard RISC-V NOP)

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            id_pc    <= 32'b0;
            id_instr <= NOP;
        end else if (!stall) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
        end
        // stall: hold values (no else needed)
    end

endmodule