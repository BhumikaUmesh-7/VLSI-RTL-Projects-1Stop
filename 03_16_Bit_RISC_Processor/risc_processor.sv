// =========================================================
// DEFINITIONS & OPCODES
// =========================================================
`define OP_NOP        5'b00000
`define OP_ADD        5'b00001
`define OP_SUB        5'b00010
`define OP_AND        5'b00011
`define OP_OR         5'b00100
`define OP_XOR        5'b00101
`define OP_NOT        5'b00110
`define OP_LW         5'b00111
`define OP_SW         5'b01000
`define OP_LDI        5'b10000
`define OP_BEQ        5'b11000

// =========================================================
// REGISTER FILE
// =========================================================
module register_file ( 
    input wire clk,
    input wire rst_n,
    input wire reg_write_en, 
    input wire [2:0] write_reg, 
    input wire [15:0] write_data, 
    input wire [2:0] read_reg_a, 
    input wire [2:0] read_reg_b, 
    output wire [15:0] read_data_a, 
    output wire [15:0] read_data_b
);
    reg [15:0] registers [0:7]; 
    integer i;

    // Internal Forwarding for WB -> ID Read-during-Write
    assign read_data_a = (reg_write_en && (write_reg != 0) && (read_reg_a == write_reg)) ? write_data : 
registers[read_reg_a];
    assign read_data_b = (reg_write_en && (write_reg != 0) && (read_reg_b == write_reg)) ? write_data : 
registers[read_reg_b];

    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) registers[i] <= 16'h0000; 
        end else if (reg_write_en && (write_reg != 0)) begin
            registers[write_reg] <= write_data;
        end
    end
endmodule

// =========================================================
// ALU MODULE
// =========================================================
module alu (
    input wire [4:0] alu_op, 
    input wire [15:0] operand_a, 
    input wire [15:0] operand_b, 
    output reg [15:0] alu_result, 
    output wire zero_flag
);
    always @(*) begin 
        case (alu_op)
            `OP_ADD: alu_result = operand_a + operand_b;
            `OP_SUB: alu_result = operand_a - operand_b;
            `OP_AND: alu_result = operand_a & operand_b;
            `OP_OR : alu_result = operand_a | operand_b;
            `OP_XOR: alu_result = operand_a ^ operand_b;
            `OP_NOT: alu_result = ~operand_a; 
             default: alu_result = 16'h0000;
        endcase
    end 

    assign zero_flag = (operand_a == operand_b); 
endmodule

// =========================================================
// FORWARDING UNIT
// =========================================================
module forwarding_unit (
    input wire [2:0] id_ex_ra, 
    input wire [2:0] id_ex_rb, 
    input wire [2:0] ex_mem_rd,
    input wire ex_mem_reg_write, 
    input wire [2:0] mem_wb_rd,
    input wire mem_wb_reg_write, 
    output reg [1:0] forward_a, 
    output reg [1:0] forward_b
);
    always @(*) begin
        // Operand A Forwarding Logic
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_ra)) 
            forward_a = 2'b10; // Forward from EX/MEM
        else if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_ra)) 
            forward_a = 2'b01; // Forward from MEM/WB
        else
            forward_a = 2'b00; // No Forwarding

        // Operand B Forwarding Logic
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rb)) 
            forward_b = 2'b10; // Forward from EX/MEM
        else if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rb)) 
            forward_b = 2'b01; // Forward from MEM/WB
        else
            forward_b = 2'b00; // No Forwarding
    end
endmodule

// =========================================================
// HAZARD DETECTION UNIT
// =========================================================
module hazard_detection_unit ( 
    input wire [2:0] id_ra, 
    input wire [2:0] id_rb, 
    input wire [2:0] id_ex_rd,
    input wire       id_ex_mem_read,
    input wire       branch_taken,
    output reg       pc_stall,
    output reg       if_id_stall,
    output reg       if_id_flush,
    output reg       id_ex_flush
);
    always @(*) begin 
        pc_stall = 1'b0; 
        if_id_stall = 1'b0; 
        if_id_flush = 1'b0; 
        id_ex_flush = 1'b0;

        // Load-Use Data Hazard Handling (1-cycle Stall Insertion)
        if (id_ex_mem_read && ((id_ex_rd == id_ra) || (id_ex_rd == id_rb))) begin 
            pc_stall = 1'b1;
            if_id_stall = 1'b1; 
            id_ex_flush = 1'b1;
        end

        // Control Hazard Handling (Branch Target Flush) 
        if (branch_taken) begin
            if_id_flush = 1'b1; 
            id_ex_flush = 1'b1;
        end
    end
endmodule

// =========================================================
// PROCESSOR TOP MODULE
// =========================================================
module processor_top ( 
    input wire         clk,
    input wire         rst_n,
    output wire [15:0] pc_out, 
    output wire [15:0] wb_result_out
);
    wire pc_stall, if_id_stall, if_id_flush, id_ex_flush; 
    wire branch_taken;
    wire [15:0] branch_target; 

    // --- Stage 1: IF (Instruction Fetch) ---
    reg [15:0] pc; 
    assign pc_out = pc;

    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            pc <= 16'h0000;
        end else if (branch_taken) begin 
            pc <= branch_target;
        end else if (!pc_stall) begin 
            pc <= pc + 1'b1;
        end
    end
    
    reg [15:0] rom [0:255];
    wire [15:0] if_instruction = rom[pc[7:0]];

    // Program Memory Initialization 
    initial begin
        rom[0] = 16'b10000_001_00001010; // LDI R1, 10 
        rom[1] = 16'b10000_010_00000101; // LDI R2, 5
        rom[2] = 16'b00001_011_001_010_00; // ADD R3, R1, R2 (R3 = 15) 
        rom[3] = 16'b00010_100_001_010_00; // SUB R4, R1, R2 (R4 = 5) 
        rom[4] = 16'b00011_101_011_100_00; // AND R5, R3, R4 (R5 = 5) 
        rom[5] = 16'b00100_110_001_010_00; // OR R6, R1, R2 (R6 = 15)
        rom[6] = 16'b01000_000_001_011_00; // SW RAM[R1], R3 (RAM[10] = 15)
        rom[7] = 16'b00111_111_001_000_00; // LW R7, RAM[R1] (R7 = 15) -> Load-Use Hazard
        rom[8] = 16'b11000_000_111_011_00; // BEQ R7 == R3? Jump PC=11 -> Branch Flush 
        rom[9] = 16'b10000_001_11111111; // Skipped (Flushed)
        rom[10] = 16'b10000_010_11111111; // Skipped (Flushed)
        rom[11] = 16'b00101_111_110_101_00; // XOR R7, R6, R5 (R7 = 10)
    end

    // --- IF/ID Register ---
    reg [15:0] if_id_instr;
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n || if_id_flush) begin
            if_id_instr <= 16'h0000;
        end else if (!if_id_stall) begin 
            if_id_instr <= if_instruction;
        end
    end

    // --- Stage 2: ID (Instruction Decode) ---
    wire [4:0] id_opcode = if_id_instr;
    wire [2:0] id_rd = if_id_instr[10:8]; 
    wire [2:0] id_ra = if_id_instr[7:5]; 
    wire [2:0] id_rb = if_id_instr[4:2]; 
    wire [7:0] id_imm8 = if_id_instr[7:0];
    
    wire id_reg_write = (id_opcode != `OP_NOP) && (id_opcode != `OP_SW) && (id_opcode != `OP_BEQ); 
    wire id_is_imm = (id_opcode == `OP_LDI);
    wire id_mem_read = (id_opcode == `OP_LW); 
    wire id_mem_write = (id_opcode == `OP_SW); 
    wire id_is_branch = (id_opcode == `OP_BEQ);
 
    wire [15:0] reg_data_a, reg_data_b;

    // --- ID/EX Register ---
    reg [4:0] id_ex_opcode;
    reg [2:0] id_ex_rd, id_ex_ra, id_ex_rb; 
    reg [15:0] id_ex_reg_a, id_ex_reg_b; 
    reg [7:0] id_ex_imm8;
    reg id_ex_reg_write, id_ex_is_imm, id_ex_mem_read, id_ex_mem_write, id_ex_is_branch;

    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n || id_ex_flush) begin
            id_ex_opcode <= 0; id_ex_rd <= 0; id_ex_ra <= 0; id_ex_rb <= 0;
            id_ex_reg_a <= 0; id_ex_reg_b <= 0; id_ex_imm8 <= 0;
            id_ex_reg_write <= 0; id_ex_is_imm <= 0; id_ex_mem_read <= 0; id_ex_mem_write <= 0; id_ex_is_branch
<= 0;
        end else begin
            id_ex_opcode <= id_opcode; 
            id_ex_rd <= id_rd;
            id_ex_ra <= id_ra;
            id_ex_rb <= id_rb; 
            id_ex_reg_a <= reg_data_a; 
            id_ex_reg_b <= reg_data_b; 
            id_ex_imm8 <= id_imm8;
            id_ex_reg_write <= id_reg_write; 
            id_ex_is_imm <= id_is_imm; 
            id_ex_mem_read <= id_mem_read; 
            id_ex_mem_write <= id_mem_write; 
            id_ex_is_branch <= id_is_branch;
        end
    end

    // --- Stage 3: EX (Execute) ---
    wire [1:0] forward_a, forward_b; 
    reg [15:0] alu_in_a, alu_in_b; 
    wire [15:0] ex_alu_out;
    wire zero_flag;
    
    reg [15:0] ex_mem_alu_out;
    reg [2:0] ex_mem_rd;
    reg ex_mem_reg_write;
    
    wire [15:0] mem_wb_data;
    wire [2:0] mem_wb_rd;
    wire mem_wb_reg_write;
    
    forwarding_unit fwd (
        .id_ex_ra(id_ex_ra),
        .id_ex_rb(id_ex_rb),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    hazard_detection_unit hazard_unit (
        .id_ra(id_ra),
        .id_rb(id_rb),
        .id_ex_rd(id_ex_rd),
        .id_ex_mem_read(id_ex_mem_read),
        .branch_taken(branch_taken),
        .pc_stall(pc_stall),
        .if_id_stall(if_id_stall),
        .if_id_flush(if_id_flush),
        .id_ex_flush(id_ex_flush)
    );

    always @(*) begin 
        case (forward_a)
            2'b10: alu_in_a = ex_mem_alu_out; 
            2'b01: alu_in_a = mem_wb_data; 
            default: alu_in_a = id_ex_reg_a;
        endcase
 
        case (forward_b)
            2'b10: alu_in_b = ex_mem_alu_out; 
            2'b01: alu_in_b = mem_wb_data; 
            default: alu_in_b = id_ex_reg_b;
        endcase
    end

    alu processor_alu (
        .alu_op(id_ex_opcode),
        .operand_a(alu_in_a),
        .operand_b(alu_in_b),
        .alu_result(ex_alu_out),
        .zero_flag(zero_flag)
    );

    assign branch_taken = id_ex_is_branch && zero_flag; 
    assign branch_target = {8'h00, id_ex_imm8};
    
    wire [15:0] ex_result = id_ex_is_imm ? {8'h00, id_ex_imm8} : ex_alu_out;
    
    // --- EX/MEM Register ---
    reg [15:0] ex_mem_write_data;
    reg ex_mem_mem_read, ex_mem_mem_write;
    
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            ex_mem_alu_out <= 0; ex_mem_rd <= 0; ex_mem_reg_write <= 0;
            ex_mem_write_data <= 0; ex_mem_mem_read <= 0; ex_mem_mem_write <= 0; 
        end else begin
            ex_mem_alu_out <= ex_result; 
            ex_mem_rd <= id_ex_rd; 
            ex_mem_reg_write <= id_ex_reg_write; 
            ex_mem_write_data <= alu_in_b; 
            ex_mem_mem_read <= id_ex_mem_read; 
            ex_mem_mem_write <= id_ex_mem_write;
        end
    end

    // --- Stage 4: MEM (Memory Access) ---
    reg [15:0] ram [0:255];
    wire [15:0] mem_read_data = ex_mem_mem_read ? ram[ex_mem_alu_out[7:0]] : 16'h0000;
    
    always @(posedge clk) begin
        if (ex_mem_mem_write) ram[ex_mem_alu_out[7:0]] <= ex_mem_write_data;
    end

    // --- MEM/WB Register ---
    reg [15:0] mem_wb_alu_out, mem_wb_mem_data; 
    reg mem_wb_mem_read;
    reg [2:0] reg_mem_wb_rd;
    reg reg_mem_wb_reg_write;
    
    assign mem_wb_rd = reg_mem_wb_rd;
    assign mem_wb_reg_write = reg_mem_wb_reg_write;
    assign mem_wb_data = mem_wb_mem_read ? mem_wb_mem_data : mem_wb_alu_out; 
    assign wb_result_out = mem_wb_data;
    
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            mem_wb_alu_out <= 0; mem_wb_mem_data <= 0; reg_mem_wb_rd <= 0;
            reg_mem_wb_reg_write <= 0; mem_wb_mem_read <= 0; 
        end else begin
            mem_wb_alu_out <= ex_mem_alu_out; 
            mem_wb_mem_data <= mem_read_data; 
            reg_mem_wb_rd <= ex_mem_rd; 
            reg_mem_wb_reg_write <= ex_mem_reg_write; 
            mem_wb_mem_read <= ex_mem_mem_read;
        end
    end
    
    // --- Stage 5: WB (Writeback Register Instantiate) ---
    register_file regfile (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write_en(mem_wb_reg_write),
        .write_reg(mem_wb_rd),
        .write_data(mem_wb_data),
        .read_reg_a(id_ra),
        .read_reg_b(id_rb),
        .read_data_a(reg_data_a),
        .read_data_b(reg_data_b)
    );
endmodule