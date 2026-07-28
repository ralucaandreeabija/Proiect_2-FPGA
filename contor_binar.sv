`timescale 1ns / 1ps

module contor_binar(

    input logic clk,
    input logic inc,
    input logic dec,
    input logic reset,

    output logic [15:0] leds

);

    always @(posedge clk) begin

        if (reset) begin
            leds <= 16'h0000;
        end

        else if (inc) begin
            leds <= leds + 16'h0001;
        end

        else if (dec) begin
            leds <= leds - 16'h0001;
        end

    end

endmodule