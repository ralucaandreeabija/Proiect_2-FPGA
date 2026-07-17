`timescale 1ns / 1ps

module baudrate_generator(
    input clk,
    output tick
    );
    
logic [13:0] counter;

always@(posedge clk) begin
    if(counter == 10416)
        counter = 0;
    else
        counter = counter + 1'b1;
end    

assign tick = (counter == 0) ? 1'b1 : 1'b0;
    
endmodule