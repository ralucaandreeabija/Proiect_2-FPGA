`timescale 1ns / 1ps

module receiver #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 9600,
    parameter integer DATA_BITS = 8
)(
    input clk,
    input reset,
    input rx,
    input tick,
    output logic [DATA_BITS-1:0] dataout,
    output logic data_valid
    );
    
localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam integer HALF_BIT = CLKS_PER_BIT / 2;
localparam integer COUNTER_WIDTH = $clog2(CLKS_PER_BIT);
localparam integer BIT_INDEX_WIDTH = $clog2(DATA_BITS);
    
typedef enum logic [1:0] { 
    IDLE, 
    START, 
    DATA, 
    STOP 
} state_r; 
  
state_r state; 
logic [COUNTER_WIDTH - 1:0] baud_counter;
logic [BIT_INDEX_WIDTH - 1:0] bit_index;
logic [DATA_BITS - 1:0] data_reg;
logic error;
  
always @(posedge clk) begin 
    if (reset) begin 
        state <= IDLE;
        baud_counter <= 1'b0;
        bit_index <= 1'b0;
        data_reg <= 1'b0;
        dataout <= 1'b0;
        error <= 1'b0;
        data_valid <= 1'b0;
    end else begin 
        case (state) 
            IDLE: begin 
                data_valid <= 1'b0;
                if (rx == 1) begin 
                    state <= IDLE;
                end 
                else begin
                    state <= START;
                end
            end 
            START: begin
                if (baud_counter < HALF_BIT) begin
                    baud_counter <= baud_counter + 1'b1;
                end
                else if (baud_counter == HALF_BIT) begin
                    if (rx == 0) begin
                        state <= DATA;
                        baud_counter <= 1'b0;
                        bit_index <= 1'b0;
                    end
                    else begin
                        state <= IDLE;
                        baud_counter <= 1'b0;
                    end
                end
            end
            DATA: begin 
                if (tick == 1) begin
                    data_reg[bit_index] <= rx;
                    if (bit_index < DATA_BITS - 1)
                        bit_index <= bit_index + 1'b1;
                    else begin
                        bit_index <= 1'b0;
                        state <= STOP;
                    end 
                end 
            end
            STOP: begin 
                if (tick == 1) begin
                    if (rx == 1) begin
                        dataout <= data_reg;
                        data_valid <= 1'b1;
                        error <= 1'b0;
                    end 
                    else begin
                        error <= 1'b1;
                    end
                 state <= IDLE;
                 end   
            end 
            default: begin 
                state <= IDLE; 
            end 
        endcase
    end  
end   

endmodule
