moduleseq_detector_1010_overlap( 
    input clk,
    input rst, 
    input din, 
    output reg dout,
    output reg [2:0] state 
);
    // State Encoding
    parameter S0 = 3'b000, // Reset / Idle 
              S1 = 3'b001, // Found "1"
              S2 = 3'b010, // Found "10" 
              S3 = 3'b011, // Found "101"
              S4 = 3'b100; // Found "1010" (Success State) reg

    [2:0] next_state;

    // State Transition Register
    always @(posedge clk or posedge rst) begin 
        if (rst) state <= S0;
        else	state <= next_state; 
    end

    // Next State Logic 
    always @(*) begin
        case(state)
            S0: next_state = din ? S1 : S0; 
            S1: next_state = din ? S1 : S2; 
            S2: next_state = din ? S3 : S0;
            S3: next_state = din ? S1 : S4; // "1010" reached if din = 0

            // OVERLAPPING RULE:
            // If din = 1, pattern becomes ...10101 -> Last 3 bits are "101" (Go to S3) 
            // If din = 0, pattern becomes ...10100 -> Resets back to start (Go to S0) 
            // S4: next_state = din ? S3 : S0;
            // NON-OVERLAPPING RULE:
            // Once "1010" is found (State 4), reset completely.
            // If din = 1, it counts as the first '1' of a brand new pattern (Go to S1). 
            // If din = 0, it resets completely to the beginning (Go to S0). S4: next_state = din ? S1 : S0;

            default: next_state = S0; 
        endcase
    end

    // Moore Output assignment (Aligned to clock boundaries) 
    always @(*) begin
        dout = (state == S4) ? 1'b1 : 1'b0; 
    end
endmodule
