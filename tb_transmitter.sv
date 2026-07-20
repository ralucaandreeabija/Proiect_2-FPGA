`timescale 1ns / 1ps

module tb_transmitter();

    logic clk;
    logic reset;
    logic tick;
    logic [7:0] datain;
    logic data_valid;

    wire tx;
    wire tx_done;

    integer i;

    transmitter uart_tx(
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .datain(datain),
        .data_valid(data_valid),
        .tx(tx),
        .tx_done(tx_done)
    );

    always #5 clk = ~clk;

    initial begin

        clk = 0;
        reset = 1;
        tick = 0;
        datain = 8'hA5;
        data_valid = 0;

        $monitor(
        "time=%0t state=%0d tick=%b data_valid=%b bit_index=%0d data_reg=%h tx=%b tx_done=%b",
        $time,
        uart_tx.state,
        tick,
        data_valid,
        uart_tx.bit_index,
        uart_tx.data_reg,
        tx,
        tx_done
        );

        // Reset
        #20
        reset = 0;

        #20
        
        data_valid = 1;

        #10
        data_valid = 0;


        // START BIT

        #104160

        tick = 1;
        #10
        tick = 0;

        // DATA BITS
        for (i = 0; i < 8; i = i + 1) begin
            #104160
            tick = 1;
            #10
            tick = 0;
        end

        // STOP BIT

        #104160

        tick = 1;
        #10
        tick = 0;

        #1000;

        $finish;

    end

endmodule