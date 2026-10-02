moduleseq_detector_1010_mealy_non_overlap( 
    input clk,
    input rst, 
    input din, 
    output reg dout,
    output reg [1:0] state 
);

    // State Encoding
    parameter S0 = 2'b00, // Initial / Reset state 
              S1 = 2'b01, // Found "1"
              S2 = 2'b10, // Found "10" 
              S3 = 2'b11; // Found "101"

    reg [1:0] next_state;

    // Sequential State Register
    always @(posedge clk or posedge rst) begin 
        if (rst)
            state <= S0; 
        else
            state <= next_state; 
    end

    // Combinational Next State & Output Logic 
    always @(*) begin
        next_state = state; 
        dout = 1'b0;

        case(state) 
            S0: begin
                if (din) next_state = S1; 
                else      next_state = S0;
            end

            S1: begin
                if (din) next_state = S1; 
                else      next_state = S2;
            end

            S2: begin
                if (din) next_state = S3; 
                else      next_state = S0;
            end

            S3: begin
                if (din) begin
                    next_state = S1; // Pattern broken: "1011" -> "1" can start a new sequence dout = 1'b0;
                end else begin
                    // NON-OVERLAPPING RULE:
                    // Pattern "1010" completed!
                    // Fire the output immediately and reset back to S0. 
                    next_state = S0;
                    dout = 1'b1; 
                end
            end
            default: next_state = S0; 
        endcase
    end 
endmodule
