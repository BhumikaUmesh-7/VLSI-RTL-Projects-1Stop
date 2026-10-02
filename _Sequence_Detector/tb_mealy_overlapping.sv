`timescale 1ns / 1ps

moduletb_seq_detector; reg clk;
    reg rst; 
    reg din; 
    wiredout;
    wire [1:0] state;

    // Instantiate Mealy FSM seq_detector_1010_mealy uut (
        .clk(clk), 
        .rst(rst), 
        .din(din), 
        .dout(dout), 
        .state(state)
);

    // 10ns Clock generator always #5 clk = ~clk;

    initial begin 
        $dumpfile("dump.vcd"); 
        $dumpvars(1, tb_seq_detector);

        clk = 0; 
        rst = 1; 
        din = 0;
        #12 rst = 0; // Release reset out of sync with clock edge

        // --- Stream sequence: 1 -> 0 -> 1 -> 0 -> 1 -> 0 ---
        @(posedge clk); #1 din = 1; // Shifts to S1
        @(posedge clk); #1 din = 0; // Shifts to S2 
        @(posedge clk); #1 din = 1; // Shifts to S3

        // Final bit of first 1010 sequence:
        @(posedge clk); #1 din = 0; // dout will go high during this clock cycle!

        // Overlapping verification bit:
        @(posedge clk); #1 din = 1; // Transitions from S2 to S3 
        @(posedge clk); #1 din = 0; // dout goes high a second time!

        @(posedge clk); #1 din = 0; // Reset back to S0 #40;
        $finish; 
    end
endmodule
