`timescale 1ns / 1ps

module logger_top(

    input logic clock,
    input btn_inc,
    input btn_dec,
    input btn_reset,
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
    logic btn_reset_db;
    
    logic btn_inc_pulse;
    logic btn_dec_pulse;
    logic btn_reset_pulse;
    
    logic overflow;
    logic underflow;
    
    logic tick;
    logic [7:0] received_data;
    logic data_valid;
    
    logic [7:0] rx_fifo_dout;
    logic rx_fifo_wr_en;
    logic rx_fifo_rd_en;
    logic rx_fifo_empty;
    logic rx_fifo_full;

    logic [7:0] tx_fifo_din;
    logic tx_fifo_wr_en;
    logic tx_fifo_full;
    logic [7:0] tx_fifo_dout;
    logic tx_fifo_empty;
    logic tx_fifo_rd_en;
    
    assign rx_fifo_wr_en = data_valid;
    
    logic [15:0] counter;
    assign leds = counter;
    
    logic inc;
    logic dec;
    logic reset;
    logic overflow;
    logic underflow;
    
    assign inc = inc_command | btn_inc_pulse;
    assign dec = dec_command | btn_dec_pulse;
  
    logic counter_reset;
    assign counter_reset = btn_reset_pulse | reset_command;
    
    logic [7:0] tx_data;
    logic tx_valid;
    logic tx_busy;
    
    debouncer #(
    .MAX_COUNT(20)
)db_inc(
        .clk(clock),
        .debouncer_input(btn_inc),
        .debouncer_output(btn_inc_db)
    );
    
    debouncer #(
    .MAX_COUNT(20)
)db_dec(
        .clk(clock),
        .debouncer_input(btn_dec),
        .debouncer_output(btn_dec_db)
    );
    
    debouncer #(
    .MAX_COUNT(20)
)db_reset(
        .clk(clock),
        .debouncer_input(btn_reset),
        .debouncer_output(btn_reset_db)
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
    
    edge_detector ed_reset(
        .clk(clock),
        .reset(reset),
        .button(btn_reset_db),
        .pulse(btn_reset_pulse)
    );
    
    fifo_generator_0 rx_fifo(
        .clk(clock),
        .srst(reset),
        .din(received_data),
        .wr_en(rx_fifo_wr_en),
        .rd_en(rx_fifo_rd_en),
        .dout(rx_fifo_dout),
        .full(rx_fifo_full),
        .empty(rx_fifo_empty)
    );
    
    receiver #(
    .CLK_FREQ(100_000_000),
    .BAUD_RATE(9600)
)uart_rx(
       .clk(clock),
       .reset(reset),
       .rx(rx),
       .dataout(received_data),
       .data_valid(data_valid)
     );
    
    command_interpreter command_interpreter_inst(
        .clk(clock),
        .reset(reset),
        .received_data(rx_fifo_dout),
        .rx_fifo_empty(rx_fifo_empty),
        .rx_fifo_rd_en(rx_fifo_rd_en),
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
        .reset(counter_reset),
        .leds(counter),
        .overflow(overflow),
        .underflow(underflow)
    );
    
   message message_inst(
       .clock(clock),
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
       .btn_reset_pulse(btn_reset_pulse),
       .overflow(overflow),
       .underflow(underflow),
       .tx_fifo_din(tx_fifo_din),
       .tx_fifo_wr_en(tx_fifo_wr_en),
       .tx_fifo_full(tx_fifo_full)
   );
   
   fifo_generator_0 tx_fifo(
       .clk(clock),
       .srst(reset),
       .din(tx_fifo_din),
       .wr_en(tx_fifo_wr_en),
       .rd_en(tx_fifo_rd_en),
       .dout(tx_fifo_dout),
       .full(tx_fifo_full),
       .empty(tx_fifo_empty)
   );
   
   transmitter #(
    .CLK_FREQ(100_000_000),
    .BAUD_RATE(9600)
)uart_tx(
        .clk(clock),
        .reset(reset),
        .fifo_dout(tx_fifo_dout),
        .fifo_empty(tx_fifo_empty),
        .fifo_rd_en(tx_fifo_rd_en),
        .tx(tx),
        .tx_done()
    );

endmodule