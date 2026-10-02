module seq_detector_1010_mealy( 
    input clk,
    input rst,
    input din, 
    output reg dout,
    output reg [1:0] state // 4 states fit perfectly into a 2-bit register bus
);
    // State Encoding
    parameter S0 = 2'b00, // Initial / Reset 
              S1 = 2'b01, // Found "1"
              S2 = 2'b10, // Found "10" 
              S3 = 2'b11; // Found "101"
    reg [1:0] next_state;

    // Sequential Block (State Register) 
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S0;
        else
            state <= next_state;
    end

    // Combinational Next State & Output Logic (Mealy style) 
    always @(*) begin
        // Default values to prevent latches 
        next_state = state;
        dout = 1'b0;

        case(state)
            S0: begin
                if (din) next_state = S1; 
                else next_state = S0;
            end

            S1: begin
                if (din) next_state = S1; 
                else next_state = S2;
                end

            S2: begin
                if (din) next_state = S3; 
                else next_state = S0;
            end

            S3: begin
                if (din) begin 
                   next_state = S1; 
                   dout = 1'b0;
            end else begin
                // OVERLAPPING RULE:
                // If din is 0 when in S3 (101), sequence "1010" is completed successfully.
                // The last "10" overlaps to start the next sequence, so go back to S2. 
                next_state = S2;
                dout = 1'b1; // Output fires IMMEDIATELY here
            end
        end
        default: next_state = S0; 
    endcase
    end
endmodule