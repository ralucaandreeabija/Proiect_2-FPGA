`timescale 1ns / 1ps

module logger_top(

    input logic clock,
    input logic cpu_resetn,
    input btn_inc,
    input btn_dec,
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
    logic [7:0] unknown_command;
    
    logic btn_inc_db;
    logic btn_dec_db;
    
    logic btn_inc_pulse;
    logic btn_dec_pulse;
    
    logic overflow;
    logic underflow;
    
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
    
    logic inc;
    logic dec;
    logic rst;
    
    assign inc = inc_command | btn_inc_pulse;
    assign dec = dec_command | btn_dec_pulse;
    assign rst = reset | reset_command;
    
    debouncer db_inc(
        .clk(clock),
        .debouncer_input(btn_inc),
        .debouncer_output(btn_inc_db)
    );
    
    debouncer db_dec(
        .clk(clock),
        .debouncer_input(btn_dec),
        .debouncer_output(btn_dec_db)
    );
    
    debouncer db_rst(
        .clk(clock),
        .debouncer_input(cpu_resetn),
        .debouncer_output()
    );
    
    edge_detector ed_inc(
        .clk(clock),
        .reset(reset),
        .button(btn_inc_db),
        .pulse(btn_inc_pulse)
    );
    
    edge_detector ed_dec(
        .clk(clock),
        .reset(reset),
        .button(btn_dec_db),
        .pulse(btn_dec_pulse)
    );
    
    edge_detector ed_rst(
        .clk(clock),
        .reset(reset),
        .button(),
        .pulse()
    );
    
    baudrate_generator baud_gen(
        .clk(clock),
        .reset(reset),
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
        .error_command(error_command),
        .unknown_command(unknown_command)
    );

    contor_binar counter_inst(
        .clk(clock),
        .inc(inc),
        .dec(dec),
        .reset(rst),
        .leds(counter),
        .overflow(overflow),
        .underflow(underflow)
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
       .unknown_command(unknown_command),
       .btn_inc_pulse(btn_inc_pulse),
       .btn_dec_pulse(btn_dec_pulse),
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