`timescale 1ns / 1ps

module tb_vending_machine; 
    reg clk;
    reg rst;
    reg select_pen, select_notebook, select_water, select_lays, select_coke; 
    reg coin_valid;
    reg [7:0] coin_value; 
    reg online_pay_req; 
    reg online_success; 
    reg cancel_txn;

    wire [2:0] state;
    wire [7:0] current_balance; 
    wire dispense;
    wire [2:0] item_dispensed;
    wire [7:0] change_returned;
    wire [7:0] refund_returned;
    
    vending_machine uut (
        .clk(clk), .rst(rst),
        .select_pen(select_pen), .select_notebook(select_notebook), .select_water(select_water),
        .select_lays(select_lays), .select_coke(select_coke),
        .coin_valid(coin_valid), .coin_value(coin_value),
        .online_pay_req(online_pay_req), .online_success(online_success),
        .cancel_txn(cancel_txn), .state(state), .current_balance(current_balance),
        .dispense(dispense), .item_dispensed(item_dispensed),
        .change_returned(change_returned), .refund_returned(refund_returned)
    );

    always #5 clk = ~clk; 

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(1, tb_vending_machine);

        clk = 0; rst = 1; cancel_txn = 0;
        select_pen = 0; select_notebook = 0; select_water = 0; select_lays = 0; select_coke = 0;
        coin_valid = 0; coin_value = 0; online_pay_req = 0; online_success = 0;
        #15 rst = 0;

        // --- TEST 1: Cash Purchase for Coke (Price 25, Paid 10+20=30) ---
        #10 select_coke = 1; #10 select_coke = 0;
        #10 coin_value = 10; coin_valid = 1; #10 coin_valid = 0;
        #20 coin_value = 20; coin_valid = 1; #10 coin_valid = 0;
        #20;

        // --- TEST 2: Online Purchase for Notebook (Price 40) ---
        #20 select_notebook = 1; online_pay_req = 1; #10 select_notebook = 0; online_pay_req = 0;
        #10 online_success = 1; #10 online_success = 0;
        #30;

        // --- TEST 3: Cancel Mid-Way (Select Lays, insert 10, cancel) ---
        #20 select_lays = 1; #10 select_lays = 0;
        #10 coin_value = 10; coin_valid = 1; #10 coin_valid = 0;
        #20 cancel_txn = 1; #10 cancel_txn = 0;

        #40;
        $finish;
    end
endmodule