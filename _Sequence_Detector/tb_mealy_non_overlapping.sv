`timescale 1ns / 1ps

moduletb_seq_detector; 
    reg clk;
    reg rst; 
    reg din; 
    wiredout;
    wire [1:0] state;

    // Instantiate Non-Overlapping Mealy FSM seq_detector_1010_mealy_non_overlap uut (
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
        #12 rst = 0; // Clear reset safely between clock cycles

        // --- Stream sequence: 1 -> 0 -> 1 -> 0 -> 1 -> 0 ---
        @(posedge clk); #1 din = 1; // Shifts to S1
        @(posedge clk); #1 din = 0; // Shifts to S2 
        @(posedge clk); #1 din = 1; // Shifts to S3

        // Final bit of the sequence:
        @(posedge clk); #1 din = 0; // FIRST MATCH: dout pulses high immediately!

        // Overlapping bits are sent here:
        @(posedge clk); #1 din = 1; // Machine was reset to S0, so this din=1 shifts to S1 
        @(posedge clk); #1 din = 0; // Shifts to S2
        @(posedge clk); #1 din = 0; // Stream breaks, back to S0 #40;
        $finish; 
    end
endmodule
