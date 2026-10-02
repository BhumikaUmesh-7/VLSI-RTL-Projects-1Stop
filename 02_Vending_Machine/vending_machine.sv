module vending_machine ( 
    input wire clk, 
    input wire rst,
    input wire select_pen, 
    input wire select_notebook, 
    input wire select_water, 
    input wire select_lays, 
    input wire select_coke, 
    input wire coin_valid, 
    input wire [7:0] coin_value, 
    input wire online_pay_req, 
    input wire online_success, 
    input wire cancel_txn, 
    output reg [2:0] state,
    output reg [7:0] current_balance, 
    output reg dispense,
    output reg [2:0] item_dispensed, 
    output reg [7:0] change_returned, 
    output reg [7:0] refund_returned
);

    localparam IDLE = 3'b000,
               SELECT_ITEM = 3'b001, 
               CASH_PAY = 3'b010, 
               ONLINE_PAY = 3'b011, 
               DISPENSE = 3'b100,
               REFUND = 3'b101;

    localparam PRICE_PEN = 8'd10,
               PRICE_NOTEBOOK = 8'd40, 
               PRICE_WATER = 8'd15, 
               PRICE_LAYS = 8'd20,
               PRICE_COKE = 8'd25;

    reg [7:0] target_price;
    reg [2:0] selected_item_reg;

    always @(posedge clk or posedge rst) begin 
        if (rst) begin
            state <= IDLE; 
            current_balance <= 8'd0; 
            target_price <= 8'd0; 
            selected_item_reg <= 3'd0;
        end else begin 
           case (state)
               IDLE: begin 
                   current_balance <= 8'd0; 
                   target_price <= 8'd0; 
                   selected_item_reg <= 3'd0;
                   state <= SELECT_ITEM;
                end

                SELECT_ITEM: begin
                    if (select_pen) begin
                        target_price <= PRICE_PEN; 
                        selected_item_reg <= 3'd1;
                        state <= online_pay_req ? ONLINE_PAY : CASH_PAY; 
                    end else if (select_notebook) begin
                        target_price <= PRICE_NOTEBOOK; 
                        selected_item_reg <= 3'd2;
                        state <= online_pay_req ? ONLINE_PAY : CASH_PAY; 
                    end else if (select_water) begin
                        target_price <= PRICE_WATER; 
                        selected_item_reg <= 3'd3;
                        state <= online_pay_req ? ONLINE_PAY : CASH_PAY; 
                    end else if (select_lays) begin
                        target_price <= PRICE_LAYS; 
                        selected_item_reg <= 3'd4;
                        state <= online_pay_req ? ONLINE_PAY : CASH_PAY; 
                    end else if (select_coke) begin
                        target_price <= PRICE_COKE; 
                        selected_item_reg <= 3'd5;
                        state <= online_pay_req ? ONLINE_PAY : CASH_PAY;
                    end
                end
                CASH_PAY: begin
                    if (cancel_txn) begin 
                        state <= REFUND;
                    end else if (coin_valid) begin
                        if ((current_balance + coin_value) >= target_price) begin 
                            current_balance <= current_balance + coin_value; 
                            state <= DISPENSE;
                        end else begin
                            current_balance <= current_balance + coin_value;
                        end
                    end
                end

                ONLINE_PAY: begin
                   if (cancel_txn) begin 
                       state <= REFUND;
                   end else if (online_success) begin 
                       current_balance <= target_price; 
                       state <= DISPENSE; 
                   end
                end

                DISPENSE: state <= IDLE; 
                REFUND: state <= IDLE;
                default: state <= IDLE; 
            endcase
        end
    end

    always @(*) begin
        dispense = 1'b0; 
        item_dispensed = 3'd0; 
        change_returned = 8'd0; 
        refund_returned = 8'd0;

        if (state == DISPENSE) begin 
            dispense = 1'b1;
            item_dispensed = selected_item_reg;
            if (current_balance > target_price) begin 
                change_returned = current_balance - target_price;
            end
        end else if (state == REFUND) begin 
            refund_returned = current_balance;
        end
    end 
endmodule