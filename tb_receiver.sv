`timescale 1ns / 1ps

module tb_receiver();

    logic clk;
    logic rst;
    logic rx_serial;
    logic tick;

    wire [7:0] rx_byte;
    wire data_valid;

    integer i;

    logic [7:0] test_data = 8'hA5;

    localparam integer HALF_BIT = 52100;
    localparam integer BIT_TIME = 104160;

    receiver uart_rx(
        .clk(clk),
        .reset(rst),
        .rx(rx_serial),
        .tick(tick),
        .dataout(rx_byte),
        .data_valid(data_valid)
    );

    always #5 clk = ~clk;

    initial begin

        clk = 0;
        rst = 1;
        rx_serial = 1;
        tick = 0;

        $monitor(
        "time=%0t state=%0d rx=%b tick=%b bit_index=%0d data_reg=%h dataout=%h valid=%b",
        $time,
        uart_rx.state,
        rx_serial,
        tick,
        uart_rx.bit_index,
        uart_rx.data_reg,
        rx_byte,
        data_valid
        );

        #20;

        rst = 0;

        #20;


        // START BIT
        rx_serial = 0;

        #HALF_BIT;


        // DATA BIT 0
        rx_serial = test_data[0];

        #BIT_TIME;

        tick = 1;
        #10;
        tick = 0;


        // DATA BITS 1...7
        for (i = 1; i < 8; i = i + 1) begin

            rx_serial = test_data[i];

            #BIT_TIME;

            tick = 1;
            #10;
            tick = 0;

        end


        // STOP BIT
        rx_serial = 1;

        #BIT_TIME;

        tick = 1;
        #10;
        tick = 0;


        #1000;

        $finish;

    end

endmodule