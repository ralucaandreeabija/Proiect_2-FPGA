`timescale 1ns / 1ps

module message(
    input logic clock,
    input logic reset,
    input logic [15:0] counter,
    // Comenzi de la command_interpreter
    input logic inc_command,
    input logic dec_command,
    input logic reset_command,
    input logic status_command,
    input logic menu_command,
    input logic error_command,
    input logic [7:0] unknown_command,
    // Interfata TX FIFO
    input logic tx_fifo_full,
    output logic [7:0] tx_fifo_din,
    output logic tx_fifo_wr_en
);

    string buffer;
    string menu_buffer;

    typedef enum logic [2:0] {
        MSG_INC,
        MSG_DEC,
        MSG_RESET,
        MSG_STATUS,
        MSG_MENU,
        MSG_ERROR
    } message_type_t;
    
    message_type_t message_type;

    typedef enum logic [2:0] {
        IDLE,
        LOAD_MESSAGE,
        SEND,
        SEND_MENU,
        SEND_HEX,
        SEND_rn
    } state_t;

    state_t state;

    integer index;
    integer message_length;
    logic [7:0] error_char;

    logic [2:0] hex_position;
    logic [7:0] hex_ascii;

    counter_to_hex hex_converter (
        .counter(counter),
        .position(hex_position),
        .ascii_char(hex_ascii)
    );

    always @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            message_type <= MSG_INC;
            index <= 0;
            message_length <= 0;
            hex_position <= 0;
            error_char <= 8'h00;
            tx_fifo_din <= 8'h00;
            tx_fifo_wr_en <= 1'b0;
            buffer = "";
            menu_buffer = "";
        end
        else begin
            tx_fifo_wr_en <= 1'b0;
            case (state)
                IDLE: begin
                    if(inc_command) begin
                        message_type <= MSG_INC;
                        state <= LOAD_MESSAGE;
                    end
                    else if(dec_command) begin
                        message_type <= MSG_DEC;
                        state <= LOAD_MESSAGE;
                    end
                    else if(reset_command) begin
                        message_type <= MSG_RESET;
                        state <= LOAD_MESSAGE;
                    end
                    else if(status_command) begin
                        message_type <= MSG_STATUS;
                        state <= LOAD_MESSAGE;
                    end
                    else if(menu_command) begin
                        message_type <= MSG_MENU;
                        state <= LOAD_MESSAGE;
                    end
                    else if(error_command) begin
                        message_type <= MSG_ERROR;
                        error_char <= unknown_command;
                        state <= LOAD_MESSAGE;
                    end
                end
                LOAD_MESSAGE: begin
                    case (message_type)
                        MSG_INC: begin
                            buffer = "[CMD] INC | Counter: ";
                            message_length = buffer.len();
                            index <= 0;
                            state <= SEND;
                        end
                        MSG_DEC: begin
                            buffer = "[CMD] DEC | Counter: ";
                            message_length = buffer.len();
                            index <= 0;
                            state <= SEND;
                        end
                        MSG_RESET: begin
                            buffer = "[CMD] RESET | Counter: ";
                            message_length = buffer.len();
                            index <= 0;
                            state <= SEND;
                        end
                        MSG_STATUS: begin
                            buffer = "[STATUS] Counter: ";
                            message_length = buffer.len();
                            index <= 0;
                            state <= SEND;
                        end
                        MSG_MENU: begin
                            menu_buffer = "Commands:\r\nI - Increment counter\r\nD - Decrement counter\r\nR - Reset counter\r\nS - Show status\r\n? - Show menu\r\n";
                            message_length = menu_buffer.len();
                            index <= 0;
                            state <= SEND_MENU;
                        end
                        MSG_ERROR: begin
                            buffer = "[ERR] Unknown: '";
                            message_length = buffer.len();
                            index <= 0;
                            state <= SEND;
                        end
                    endcase
                end
                SEND: begin
                    if(!tx_fifo_full) begin
                        tx_fifo_din <= buffer[index];
                        tx_fifo_wr_en <= 1'b1;
                        if(index == message_length - 1) begin
                            if(message_type == MSG_ERROR) begin
                                tx_fifo_din <= buffer[index];
                                state <= SEND_HEX;
                            end
                            else begin
                                hex_position <= 0;
                                state <= SEND_HEX;
                            end
                        end
                        else begin
                            index <= index + 1;
                        end
                    end
                end
                SEND_MENU: begin
                    if(!tx_fifo_full) begin
                        tx_fifo_din <= menu_buffer[index];
                        tx_fifo_wr_en <= 1'b1;
                        if (index == message_length - 1) begin
                            state <= IDLE;
                        end
                        else begin
                            index <= index + 1;
                        end
                    end
                end
                SEND_HEX: begin
                    if(!tx_fifo_full) begin
                        if(message_type == MSG_ERROR) begin
                            tx_fifo_din <= error_char;
                            tx_fifo_wr_en <= 1'b1;
                            state <= SEND_rn;
                        end
                        else begin
                            tx_fifo_din <= hex_ascii;
                            tx_fifo_wr_en <= 1'b1;
                            if (hex_position == 5) begin
                                state <= SEND_rn;
                            end
                            else begin
                                hex_position <= hex_position + 1;
                            end
                        end
                    end
                end
                SEND_rn: begin
                    if(!tx_fifo_full) begin
                        if(index == 0) begin
                            tx_fifo_din <= 8'h0D;
                            tx_fifo_wr_en <= 1'b1;
                            index <= 1;
                        end
                        else begin
                            tx_fifo_din <= 8'h0A;
                            tx_fifo_wr_en <= 1'b1;
                            index <= 0;
                            state <= IDLE;
                        end
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule