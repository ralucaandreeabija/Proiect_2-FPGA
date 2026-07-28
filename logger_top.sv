`timescale 1ns / 1ps

module logger_top(

    input logic clock,
    input logic cpu_resetn,
    input logic rx,
    output logic tx,
    output logic [15:0] leds
);

    logic inc_command;
    logic dec_command;
    logic reset_command;
    logic status_command;
    logic menu_command;
    logic error_command;

    logic tick;
    logic [7:0] received_data;
    logic data_valid;

    logic [7:0] tx_fifo_din;
    logic tx_fifo_wr_en;
    logic tx_fifo_full;

    logic [7:0] fifo_dout;
    logic fifo_empty;
    logic fifo_rd_en;
    
    logic reset;
    assign reset = ~cpu_resetn;
    
    logic [15:0] counter;
    assign leds = counter;
    
    baudrate_generator baud_gen(
        .clk(clock),
        .tick(tick)
    );
    
    receiver uart_rx(
       .clk(clock),
       .reset(reset),
       .rx(rx),
       .dataout(received_data),
       .data_valid(data_valid)
     );
    
    command_interpreter command_interpreter_inst(
        .clk(clock),
        .reset(reset),
        .received_data(received_data),
        .data_valid(data_valid),
        .inc_command(inc_command),
        .dec_command(dec_command),
        .reset_command(reset_command),
        .status_command(status_command),
        .menu_command(menu_command),
        .error_command(error_command)
    );

    contor_binar counter_inst(
        .clk(clock),
        .inc(inc_command),
        .dec(dec_command),
        .reset(reset | reset_command),
        .leds(counter)
    );
    
   message message_inst(
       .clock(clock),
       .reset(reset),
       .counter(counter),
       .inc_command(inc_command),
       .dec_command(dec_command),
       .reset_command(reset_command),
       .status_command(status_command),
       .menu_command(menu_command),
       .error_command(error_command),
       .unknown_command(received_data),
       .tx_fifo_full(tx_fifo_full),
       .tx_fifo_din(tx_fifo_din),
       .tx_fifo_wr_en(tx_fifo_wr_en)
   );
   
   fifo_generator_0 fifo_inst(
       .clk(clock),
       .srst(reset),
       .din(tx_fifo_din),
       .wr_en(tx_fifo_wr_en),
       .rd_en(fifo_rd_en),
       .dout(fifo_dout),
       .full(tx_fifo_full),
       .empty(fifo_empty)
   );
   
   transmitter uart_tx (
       .clk(clock),
       .reset(reset),
       .tick(tick),
       .fifo_dout(fifo_dout),
       .fifo_empty(fifo_empty),
       .fifo_rd_en(fifo_rd_en),
       .tx(tx),
       .tx_done()
   );

endmodule