`timescale 1ns / 1ps

module tb_uart();

    logic clk;
    logic reset;
    logic rx_serial;
    logic tx_serial;
    logic tick;
    logic [7:0] received_data;
    logic data_valid;
    logic tx_done;

    integer i;

    logic [7:0] test_data = 8'hA5;

    receiver uart_receiver (
        .clk(clk),
        .reset(reset),
        .rx(rx_serial),
        .tick(tick),
        .dataout(received_data),
        .data_valid(data_valid)
    );

    transmitter uart_transmitter (
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .datain(received_data),
        .data_valid(data_valid),
        .tx(tx_serial),
        .tx_done(tx_done)
    );

    always #5 clk = ~clk;

    initial begin

        clk = 0;
        reset = 1;
        rx_serial = 1;
        tick = 0;

        #20

        reset = 0;

        #20

        rx_serial = 1;

        #100

        rx_serial = 0;

        #104160

        for (i = 0; i < 8; i = i + 1) begin
            rx_serial = test_data[i];
            #104160
            tick = 1;
            #10
            tick = 0;
        end

        rx_serial = 1;

        #104160

        tick = 1;

        #10

        tick = 0;

        #1000000;

        $finish;
    end

    // Monitorizare
    initial begin

        $monitor(
            "time=%0t | RX=%b | state_RX=%0d | data=%h | valid=%b | TX=%b | state_TX=%0d | done=%b",
            $time,
            rx_serial,
            uart_receiver.state,
            received_data,
            data_valid,
            tx_serial,
            uart_transmitter.state,
            tx_done
        );

    end

endmodule