
module riscv_top (
    input  wire        clk,
    input  wire        rst,
    output wire [3:0]  debug_leds,
    output wire        debug_valid
);
 
    // ----------------------------------------------------------
    // 1a. IF stage outputs
    // ----------------------------------------------------------
    wire [31:0] if_pc;
    wire [31:0] if_instr;
 
    // ----------------------------------------------------------
    // 1b. IF/ID register outputs
    // ----------------------------------------------------------
    wire [31:0] id_pc;
    wire [31:0] id_instr;
 
    // ----------------------------------------------------------
    // 1c. ID stage outputs
    // ----------------------------------------------------------
    wire [31:0] id_rs1_data, id_rs2_data, id_rs3_data;
    wire [31:0] id_imm_ext;
    wire [4:0]  id_rs1, id_rs2, id_rs3, id_rd;
    wire        id_reg_write, id_mem_read, id_mem_write;
    wire        id_branch, id_alu_src, id_mem_to_reg;
    wire        id_xmac_en;
    wire [3:0]  id_alu_op;
 
    // ----------------------------------------------------------
    // 1d. ID/EX register outputs
    // ----------------------------------------------------------
    wire [31:0] ex_pc;
    wire [31:0] ex_rs1_data, ex_rs2_data, ex_rs3_data;
    wire [31:0] ex_imm_ext;
    wire [4:0]  ex_rs1, ex_rs2, ex_rs3, ex_rd;
    wire        ex_reg_write, ex_mem_read, ex_mem_write;
    wire        ex_branch, ex_alu_src, ex_mem_to_reg;
    wire        ex_xmac_en;
    wire [3:0]  ex_alu_op;
 
    // ----------------------------------------------------------
    // 1e. EX stage outputs
    // ----------------------------------------------------------
    wire [31:0] ex_alu_result;
    wire [31:0] ex_branch_target;
    wire        ex_branch_taken;
    wire [31:0] ex_rs2_fwd;
 
    // ----------------------------------------------------------
    // 1f. EX/MEM register outputs
    // ----------------------------------------------------------
    wire [31:0] mem_alu_result;
    wire [31:0] mem_rs2_data;
    wire [4:0]  mem_rd;
    wire        mem_reg_write, mem_mem_read, mem_mem_write;
    wire        mem_mem_to_reg;
 
    // ----------------------------------------------------------
    // 1g. MEM stage outputs
    // ----------------------------------------------------------
    wire [31:0] mem_read_data;
 
    // ----------------------------------------------------------
    // ----------------------------------------------------------
    // 1h. MEM/WB register outputs
    // ----------------------------------------------------------
    wire [31:0] wb_alu_result;
    wire [31:0] wb_mem_read_data;
    wire [4:0]  wb_rd;
    wire        wb_reg_write;
    wire        wb_mem_to_reg;    // ← ADD

    // ----------------------------------------------------------
    // 1i. WB stage outputs
    // ----------------------------------------------------------
    wire [31:0] wb_data;          // ← MOVE here from 1h

    // ----------------------------------------------------------
    // 1j. Hazard unit outputs
    // ----------------------------------------------------------
    wire        hz_stall_if;
    wire        hz_stall_id;      // ← ADD
    wire        hz_flush_ex;
    wire        hz_flush_id;
 
    // ----------------------------------------------------------
    // 1k. Forwarding unit outputs
    // ----------------------------------------------------------
    wire [1:0]  fwd_a;
    wire [1:0]  fwd_b;
    wire [1:0]  fwd_c;
 
    // ==========================================================
    // INSTANTIATIONS
    // ==========================================================
 
    // ── Stage 1: Instruction Fetch ────────────────────────────
    if_stage u_if (
        .clk            (clk),
        .rst            (rst),
        .stall          (hz_stall_if),
        .branch_taken   (ex_branch_taken),
        .branch_target  (ex_branch_target),
        .pc             (if_pc),
        .instr          (if_instr)
    );
 
    // ── Pipeline Register: IF/ID ──────────────────────────────
    // stall = hz_stall_if (same signal freezes IF and IF/ID)
    pipe_if_id u_pipe_if_id (
        .clk            (clk),
        .rst            (rst),
        .stall          (hz_stall_if),
        .flush          (hz_flush_id),
        .if_pc          (if_pc),
        .if_instr       (if_instr),
        .id_pc          (id_pc),
        .id_instr       (id_instr)
    );
 
    // ── Stage 2: Instruction Decode ───────────────────────────
    id_stage u_id (
        .clk            (clk),
        .rst            (rst),
        .instr          (id_instr),
        .wb_reg_write   (wb_reg_write),
        .wb_rd          (wb_rd),
        .wb_data        (wb_data),
        .rs1_data       (id_rs1_data),
        .rs2_data       (id_rs2_data),
        .rs3_data       (id_rs3_data),
        .imm_ext        (id_imm_ext),
        .rs1            (id_rs1),
        .rs2            (id_rs2),
        .rs3            (id_rs3),
        .rd             (id_rd),
        .reg_write      (id_reg_write),
        .mem_read       (id_mem_read),
        .mem_write      (id_mem_write),
        .branch         (id_branch),
        .alu_src        (id_alu_src),
        .mem_to_reg     (id_mem_to_reg),
        .xmac_en        (id_xmac_en),
        .alu_op         (id_alu_op)
    );
 
    // ── Pipeline Register: ID/EX ──────────────────────────────
    // stall = hz_stall_if (same stall signal)
    pipe_id_ex u_pipe_id_ex (
        .clk            (clk),
        .rst            (rst),
        .flush          (hz_flush_ex),
        .stall          (hz_stall_if),
        .id_pc          (id_pc),
        .id_rs1_data    (id_rs1_data),
        .id_rs2_data    (id_rs2_data),
        .id_rs3_data    (id_rs3_data),
        .id_imm_ext     (id_imm_ext),
        .id_rs1         (id_rs1),
        .id_rs2         (id_rs2),
        .id_rs3         (id_rs3),
        .id_rd          (id_rd),
        .id_reg_write   (id_reg_write),
        .id_mem_read    (id_mem_read),
        .id_mem_write   (id_mem_write),
        .id_branch      (id_branch),
        .id_alu_src     (id_alu_src),
        .id_mem_to_reg  (id_mem_to_reg),
        .id_xmac_en     (id_xmac_en),
        .id_alu_op      (id_alu_op),
        .ex_pc          (ex_pc),
        .ex_rs1_data    (ex_rs1_data),
        .ex_rs2_data    (ex_rs2_data),
        .ex_rs3_data    (ex_rs3_data),
        .ex_imm_ext     (ex_imm_ext),
        .ex_rs1         (ex_rs1),
        .ex_rs2         (ex_rs2),
        .ex_rs3         (ex_rs3),
        .ex_rd          (ex_rd),
        .ex_reg_write   (ex_reg_write),
        .ex_mem_read    (ex_mem_read),
        .ex_mem_write   (ex_mem_write),
        .ex_branch      (ex_branch),
        .ex_alu_src     (ex_alu_src),
        .ex_mem_to_reg  (ex_mem_to_reg),
        .ex_xmac_en     (ex_xmac_en),
        .ex_alu_op      (ex_alu_op)
    );
 
    // ── Stage 3: Execute ──────────────────────────────────────
    // xmac_unit is instantiated INSIDE ex_stage - not here
    ex_stage u_ex (
        .pc             (ex_pc),
        .rs1_data       (ex_rs1_data),
        .rs2_data       (ex_rs2_data),
        .rs3_data       (ex_rs3_data),
        .imm_ext        (ex_imm_ext),
        .alu_op         (ex_alu_op),
        .alu_src        (ex_alu_src),
        .branch         (ex_branch),
        .xmac_en        (ex_xmac_en),
        .forward_a      (fwd_a),
        .forward_b      (fwd_b),
        .forward_c      (fwd_c),
        .ex_mem_result  (mem_alu_result),
        .mem_wb_result  (wb_data),
        .wb_result      (wb_data),
        .alu_result     (ex_alu_result),
        .rs2_forwarded  (ex_rs2_fwd),
        .branch_target  (ex_branch_target),
        .branch_taken   (ex_branch_taken)
    );
 
    // ── Pipeline Register: EX/MEM ─────────────────────────────
    pipe_ex_mem u_pipe_ex_mem (
        .clk            (clk),
        .rst            (rst),
        .ex_alu_result  (ex_alu_result),
        .ex_rs2_data    (ex_rs2_fwd),
        .ex_rd          (ex_rd),
        .ex_reg_write   (ex_reg_write),
        .ex_mem_read    (ex_mem_read),
        .ex_mem_write   (ex_mem_write),
        .ex_mem_to_reg  (ex_mem_to_reg),
        .mem_alu_result (mem_alu_result),
        .mem_rs2_data   (mem_rs2_data),
        .mem_rd         (mem_rd),
        .mem_reg_write  (mem_reg_write),
        .mem_mem_read   (mem_mem_read),
        .mem_mem_write  (mem_mem_write),
        .mem_mem_to_reg (mem_mem_to_reg)
    );
 
    // ── Stage 4: Memory Access ────────────────────────────────
    mem_stage u_mem (
        .clk            (clk),
        .mem_read       (mem_mem_read),
        .mem_write      (mem_mem_write),
        .addr           (mem_alu_result),
        .write_data     (mem_rs2_data),
        .read_data      (mem_read_data)
    );
 
    // ── Pipeline Register: MEM/WB ─────────────────────────────
    pipe_mem_wb u_pipe_mem_wb (
        .clk            (clk),
        .rst            (rst),
        .mem_alu_result (mem_alu_result),
        .mem_read_data  (mem_read_data),
        .mem_rd         (mem_rd),
        .mem_reg_write  (mem_reg_write),
        .mem_mem_to_reg (mem_mem_to_reg),
        .wb_alu_result  (wb_alu_result),
        .wb_read_data   (wb_mem_read_data),
        .wb_rd          (wb_rd),
        .wb_reg_write   (wb_reg_write),
        .wb_mem_to_reg  (wb_mem_to_reg)
    );
 
    // ── Stage 5: Write Back ───────────────────────────────────
    wb_stage u_wb (
        .mem_to_reg     (wb_mem_to_reg),
        .alu_result     (wb_alu_result),
        .mem_read_data  (wb_mem_read_data),
        .wb_data        (wb_data)
    );
 
    // ── Hazard Detection Unit ─────────────────────────────────
    hazard_unit u_hazard (
        .id_ex_mem_read (ex_mem_read),
        .id_ex_rd       (ex_rd),
        .if_id_rs1      (id_rs1),
        .if_id_rs2      (id_rs2),
        .branch_taken   (ex_branch_taken),
        .stall          (hz_stall_if),
        .flush_id       (hz_flush_id),
        .flush_ex       (hz_flush_ex)
    );
 
    // ── Forwarding Unit ───────────────────────────────────────
    forwarding_unit u_fwd (
        .id_ex_rs1       (ex_rs1),
        .id_ex_rs2       (ex_rs2),
        .id_ex_rs3       (ex_rs3),
        .id_ex_xmac_en   (ex_xmac_en),
        .ex_mem_rd       (mem_rd),
        .ex_mem_reg_write(mem_reg_write),
        .mem_wb_rd       (wb_rd),
        .mem_wb_reg_write(wb_reg_write),
        .wb_rd            (wb_rd),         
        .wb_reg_write     (wb_reg_write),
        .forward_a       (fwd_a),
        .forward_b       (fwd_b),
        .forward_c       (fwd_c)
    );
 
        
    assign hz_stall_id = hz_stall_if;   
    assign debug_leds  = wb_data[3:0];
    assign debug_valid = wb_reg_write;
   
endmodule