`timescale 1ns / 1ps

module top_uart #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 9600,
    parameter integer DATA_BITS = 8
)(
    input logic clk,
    input logic reset,
    input logic rx,
    output logic tx
    );
    
    logic tick;
    logic [DATA_BITS - 1:0] received_data;
    logic data_valid;
    logic tx_done;

    baudrate_generator #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    )baud_gen(
        .clk(clk),
        .tick(tick)
    );

    receiver #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS)
    )uart_receiver(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tick(tick),
        .dataout(received_data),
        .data_valid(data_valid)
    );

    transmitter #(
        .DATA_BITS(DATA_BITS)
    )uart_transmitter(
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .datain(received_data),
        .data_valid(data_valid),
        .tx(tx),
        .tx_done(tx_done)
    );
    
endmodule
