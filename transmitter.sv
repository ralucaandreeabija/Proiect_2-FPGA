`timescale 1ns / 1ps

module transmitter #(
    parameter integer DATA_BITS = 8
)(
    input clk,
    input reset,
    input tick,
    input [DATA_BITS-1:0] datain,
    input data_valid,
    output logic tx,
    output logic tx_done
    );

localparam integer BIT_INDEX_WIDTH = $clog2(DATA_BITS);
    
typedef enum logic [1:0] { 
    IDLE, 
    START, 
    DATA, 
    STOP 
} state_t; 
  
state_t state;     
logic [BIT_INDEX_WIDTH - 1:0] bit_index;
logic [DATA_BITS - 1:0] data_reg;
  
always @(posedge clk) begin 
    if (reset) begin 
        state <= IDLE;
        bit_index <= 1'b0;
        data_reg <= 1'b0;
    end else begin 
        case (state) 
            IDLE: begin 
                tx <= 1'b1;
                tx_done <= 1'b0;
                if(data_valid == 1) begin
                    data_reg <= datain;
                    bit_index <= 1'b0;
                    state <= START;
                end
            end 
            START: begin
                tx <= 1'b0;
                if (tick == 1)
                    state <= DATA;
            end
            DATA: begin 
                tx <= data_reg[bit_index];
                if (tick == 1) begin
                    if (bit_index < DATA_BITS - 1)
                        bit_index <= bit_index + 1'b1;
                    else begin
                        bit_index <= 1'b0;
                        state <= STOP;
                    end
                 end
            end
            STOP: begin 
                tx <= 1;
                if (tick == 1) begin
                    tx_done <= 1'b1;
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
