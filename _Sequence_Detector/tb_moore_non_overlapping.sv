`timescale 1ns / 1ps

moduletb_seq_detector; 
    reg clk;
    reg rst; 
    reg din; 
    wiredout;
    wire [2:0] state;

    // Connect to your design seq_detector_1010_overlap uut (
        .clk(clk), 
        .rst(rst), 
        .din(din), 
        .dout(dout), 
        .state(state)
    );

    // 10ns Clock cycle configuration 
    always #5 clk = ~clk;

    initial begin 
        $dumpfile("dump.vcd"); 
        $dumpvars(1, tb_seq_detector); 
        // Reset the system initially 
        clk = 0;
        rst = 1; 
        din = 0; 
        #12;
        rst = 0; // Release reset cleanly between clock transitions

        // --- Stream sequence sequence: 1 -> 0 -> 1 -> 0 -> 1 -> 0 ---
        @(posedge clk); #1 din = 1; // Shifting to State 1
        @(posedge clk); #1 din = 0; // Shifting to State 2 
        @(posedge clk); #1 din = 1; // Shifting to State 3
        @(posedge clk); #1 din = 0; // Hits State 4! (dout turns 1 on next cycle)

        // Testing Overlapping mechanics
        @(posedge clk); #1 din = 1; // Loops back to State 3 safely 
        @(posedge clk); #1 din = 0; // Hits State 4 again!

        // Resetting sequence pattern
        @(posedge clk); #1 din = 0; // Back to State 0 
        #40;
        $finish; 
    end
endmodule
