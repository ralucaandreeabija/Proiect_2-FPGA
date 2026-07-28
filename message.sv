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

    localparam BYTES = 32;
    localparam MENU_BYTES = 128;
    
    logic [8*BYTES-1:0] buffer;
    logic [8*MENU_BYTES-1:0] menu_buffer;
    
    logic [7:0] bytes_left;
    
    localparam LEN_INC = 29;
    localparam LEN_DEC = 29;
    localparam LEN_RESET = 31;
    localparam LEN_STATUS = 26;
    localparam LEN_ERROR = 19;
    localparam LEN_MENU = 121;

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
        WAIT_COUNTER,
        LOAD_MESSAGE,
        SEND,
        SEND_MENU
    } state_t;

    state_t state;

    logic [7:0] error_char;

    logic [2:0] hex_position;
    logic [47:0] hex_ascii;

    counter_to_hex hex_converter (
        .counter(counter),
        .ascii_hex(hex_ascii)
    );

    always @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            hex_position <= 1'b0;
            error_char <= 8'h00;
            tx_fifo_din <= 8'h00;
            tx_fifo_wr_en <= 1'b0;
            buffer <= 1'b0;
            menu_buffer <= 1'b0;
            bytes_left <= 1'b0;
        end
        else begin
            tx_fifo_wr_en <= 1'b0;
            case (state)
                IDLE: begin
                    if(inc_command) begin
                        message_type <= MSG_INC;
                        state <= WAIT_COUNTER;
                    end
                    else if(dec_command) begin
                        message_type <= MSG_DEC;
                        state <= WAIT_COUNTER;
                    end
                    else if(reset_command) begin
                        message_type <= MSG_RESET;
                        state <= WAIT_COUNTER;
                    end
                    else if(status_command) begin
                        message_type <= MSG_STATUS;
                        state <= WAIT_COUNTER;
                    end
                    else if(menu_command) begin
                        message_type <= MSG_MENU;
                        state <= WAIT_COUNTER;
                    end
                    else if(error_command) begin
                        message_type <= MSG_ERROR;
                        error_char <= unknown_command;
                        state <= WAIT_COUNTER;
                    end
                end
                WAIT_COUNTER: begin
                    state <= LOAD_MESSAGE;
                end
                LOAD_MESSAGE: begin
                    case (message_type)
                        MSG_INC: begin
                            buffer <= {"[CMD] INC | Counter: ",hex_ascii,8'h0D,8'h0A,{(BYTES-LEN_INC){8'h00}}};
                            bytes_left <= LEN_INC;
                            state <= SEND;
                        end
                        MSG_DEC: begin
                            buffer <= {"[CMD] DEC | Counter: ",hex_ascii,8'h0D,8'h0A,{(BYTES-LEN_DEC){8'h00}}};
                            bytes_left <= LEN_DEC;
                            state <= SEND;
                        end
                        MSG_RESET: begin
                            buffer <= {"[CMD] RESET | Counter: ",hex_ascii,8'h0D,8'h0A,{(BYTES-LEN_RESET){8'h00}}};
                            bytes_left <= LEN_RESET;
                            state <= SEND;
                        end
                        MSG_STATUS: begin
                            buffer <= {"[STATUS] Counter: ",hex_ascii,8'h0D,8'h0A,{(BYTES-LEN_STATUS){8'h00}}};
                            bytes_left <= LEN_STATUS;
                            state <= SEND;
                        end
                        MSG_MENU: begin
                            menu_buffer <= {"Commands:",8'h0D,8'h0A,"I/i - Increment counter",8'h0D,8'h0A,"D/d - Decrement counter",8'h0D,8'h0A,"R/r - Reset counter",8'h0D,8'h0A,"S/s - Show status",8'h0D,8'h0A,"?   - Show menu",8'h0D,8'h0A,{(MENU_BYTES-LEN_MENU){8'h00}}};
                            bytes_left <= LEN_MENU;
                            state <= SEND_MENU;
                        end
                        MSG_ERROR: begin
                            buffer <= {"[ERR] Unknown: ",error_char,"'",8'h0D,8'h0A,{(BYTES-LEN_ERROR){8'h00}}};
                            bytes_left <= LEN_ERROR;
                            state <= SEND;
                        end
                    endcase
                end
                SEND: begin
                     if (!tx_fifo_full && bytes_left != 0) begin
                        tx_fifo_din <= buffer[8*BYTES-1 : 8*BYTES-8];
                        tx_fifo_wr_en <= 1'b1;
                        buffer <= buffer << 8;
                        bytes_left <= bytes_left - 1;
                        if (bytes_left == 1) begin
                            state <= IDLE;
                        end
                    end
                end
                SEND_MENU: begin
                     if (!tx_fifo_full && bytes_left != 0) begin
                        tx_fifo_din <= menu_buffer[8*MENU_BYTES-1 : 8*MENU_BYTES-8];
                        tx_fifo_wr_en <= 1'b1;
                        menu_buffer <= menu_buffer << 8;
                        bytes_left <= bytes_left - 1;
                        if (bytes_left == 1) begin
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