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

receiver uart_rx(
    .clk(clk),
    .reset(rst),
    .rx(rx_serial),
    .tick(tick),
    .dataout(rx_byte),
    .data_valid(data_valid)
    );

always #5 clk = ~clk;

    always begin
        tick = 0;
        #(104160);
        tick = 1;
        #10;
        tick = 0;
    end

    initial begin
        clk = 0;
        rst = 1;
        rx_serial = 1;
        #20;
        rst = 0;
        #20;

        rx_serial = 0;
        #(104160);
        
        for (i = 0; i < 8; i = i + 1) begin
            rx_serial = test_data[i];
            #(104160);
        end
        
        rx_serial = 1;
        #(104160);

        $finish;
    end
endmodule
