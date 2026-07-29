`timescale 1ns / 1ps

module baudrate_generator #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 9600
)(
    input clk,
    input reset,
    output tick
    );

localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam integer COUNTER_WIDTH = $clog2(CLKS_PER_BIT);
logic [COUNTER_WIDTH-1:0] counter;   

always@(posedge clk) begin
    if(reset)
        counter <= 1'b0;
    else if(counter == CLKS_PER_BIT - 1)
        counter <= 1'b0;
    else
        counter <= counter + 1'b1;
end    

assign tick = (counter == 0) ? 1'b1 : 1'b0;
    
endmodule