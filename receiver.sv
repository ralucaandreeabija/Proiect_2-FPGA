`timescale 1ns / 1ps

module receiver(
    input clk,
    input reset,
    input rx,
    input tick,
    output logic [7:0] dataout,
    output logic data_valid
    );
    
typedef enum logic [1:0] { 
    IDLE, 
    START, 
    DATA, 
    STOP 
} state_r; 
  
state_r state; 
logic [13:0] baud_counter;
logic [2:0] bit_index;
logic [7:0] data_reg;
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
                if (baud_counter < 5208) begin
                    baud_counter <= baud_counter + 1'b1;
                end
                else if (baud_counter == 5208) begin
                    if (rx == 0)
                            state <= DATA;
                        else begin
                            state <= IDLE;
                            baud_counter <= 0;
                        end
                end
            end
            DATA: begin 
                if (tick == 1) begin
                    data_reg[bit_index] <= rx;
                    if (bit_index < 7)
                        bit_index <= bit_index + 1'b1;
                    else begin
                        bit_index <= 0;
                        state <= STOP;
                    end 
                end 
            end
            STOP: begin 
                if (tick == 1) begin
                    if (rx == 1) begin
                        dataout <= data_reg;
                        data_valid <= 1'b1;
                        error <= 0;
                    end else
                        error <= 1;
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
