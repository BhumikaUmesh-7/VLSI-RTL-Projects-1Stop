`timescale 1ns / 1ps

module processor_top_tb; 
    reg clk;
    reg rst_n;
    wire [15:0] pc_out;
    wire [15:0] wb_result_out;
    
    // Unit Under Test (UUT) 
    processor_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_out(pc_out),
        .wb_result_out(wb_result_out)
    );
    
    // Clock Generator (100MHz / 10ns cycle) 
    always #5 clk = ~clk;
    
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, processor_top_tb);
        
        clk = 0;
        rst_n = 0;
        
        $display("==========================================================");
        $display(" STARTING FULL CORE ARCHITECTURAL VERIFICATION ");
        $display("==========================================================");
        
        #15 rst_n = 1; // Release reset 
        
        repeat (20) @(posedge clk);
        
        #5;
        $display("\n==========================================================");
        $display(" FINAL REGISTER FILE DUMP ");
        $display("==========================================================");
        $display(" R0 = %d (Zero Register)", uut.regfile.registers[0]);
        $display(" R1 = %d", uut.regfile.registers[1]);
        $display(" R2 = %d", uut.regfile.registers[2]);
        $display(" R3 = %d", uut.regfile.registers[3]);
        $display(" R4 = %d", uut.regfile.registers[4]);
        $display(" R5 = %d", uut.regfile.registers[5]);
        $display(" R6 = %d", uut.regfile.registers[6]);
        $display(" R7 = %d", uut.regfile.registers[7]);
        $display("==========================================================");
        $display(" RAM[10] (Memory Address 10 Value) = %d", uut.ram[10]);
        $display("==========================================================\n");
        
        $finish;
    end 
endmodule