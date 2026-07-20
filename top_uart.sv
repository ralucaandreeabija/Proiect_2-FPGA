`timescale 1ns / 1ps

module top_uart(
    input logic clk,
    input logic reset,
    input logic rx,
    output logic tx
    );
    
    logic tick;
    logic [7:0] received_data;
    logic data_valid;
    logic tx_done;

    baudrate_generator baud_gen(
        .clk(clk),
        .tick(tick)
    );

    receiver uart_receiver(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tick(tick),
        .dataout(received_data),
        .data_valid(data_valid)
    );

    transmitter uart_transmitter(
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .datain(received_data),
        .data_valid(data_valid),
        .tx(tx),
        .tx_done(tx_done)
    );
    
endmodule
