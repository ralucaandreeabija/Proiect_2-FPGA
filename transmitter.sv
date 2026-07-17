`timescale 1ns / 1ps

module transmitter(
    input clk,
    input reset,
    input tick,
    input [7:0] datain,
    input data_valid,
    output logic tx,
    output logic tx_done
    );
    
typedef enum logic [1:0] { 
    IDLE, 
    START, 
    DATA, 
    STOP 
} state_t; 
  
state_t state;     
logic [2:0] bit_index;
logic [7:0] data_reg;
  
always @(posedge clk) begin 
    if (reset) begin 
        state <= IDLE;
        bit_index <= 0;
        data_reg <= 0;
    end else begin 
        case (state) 
            IDLE: begin 
                tx <= 1;
                tx_done <= 0;
                if(data_valid == 1) begin
                    data_reg <= datain;
                    bit_index <= 0;
                    state <= START;
                end
            end 
            START: begin
                tx <= 0;
                if (tick == 1)
                    state <= DATA;
            end
            DATA: begin 
                tx <= data_reg[bit_index];
                if (tick == 1) begin
                    if (bit_index < 7)
                        bit_index <= bit_index + 1'b1;
                    else begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                 end
            end
            STOP: begin 
                tx <= 1;
                if (tick == 1) begin
                    tx_done <= 1;
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
