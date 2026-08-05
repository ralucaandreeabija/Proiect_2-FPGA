`timescale 1ns / 1ps

module message(
    input logic clock,
    input logic [15:0] counter,
    // Comenzi de la command_interpreter
    input logic inc_command,
    input logic dec_command,
    input logic reset_command,
    input logic status_command,
    input logic menu_command,
    input logic error_command,
    input logic [7:0] unknown_command,
    // Comenzi de la butoane
    input btn_inc_pulse,
    input btn_dec_pulse,
    input btn_reset_pulse,
    input logic overflow,
    input logic underflow,
    // Interfata TX FIFO
    output logic [7:0] tx_fifo_din,
    output logic tx_fifo_wr_en,
    input logic tx_fifo_full
);

    localparam BYTES = 48;
    localparam MENU_BYTES = 128;
    
    localparam LEN_INC = 29;
    localparam LEN_DEC = 29;
    localparam LEN_RESET = 31;
    localparam LEN_STATUS = 26;
    localparam LEN_ERROR = 22;
    localparam LEN_MENU = 121;
    localparam LEN_BTN_INC = 29;
    localparam LEN_BTN_DEC = 29;
    localparam LEN_BTN_RESET = 31;
    localparam LEN_WELCOME = 50;
    localparam LEN_OVERFLOW = 27;
    localparam LEN_UNDERFLOW = 27;

    typedef enum logic [3:0] {
        MSG_INC,
        MSG_DEC,
        MSG_RESET,
        MSG_STATUS,
        MSG_MENU,
        MSG_ERROR,
        MSG_BTN_INC,
        MSG_BTN_DEC,
        MSG_BTN_RESET,
        MSG_OVERFLOW,
        MSG_UNDERFLOW,
        MSG_WELCOME
    } message_type_t;
    
    message_type_t message_type;

    typedef enum logic [2:0] {
        IDLE,
        WAIT_COUNTER,
        LOAD_MESSAGE,
        SEND,
        SEND_MENU
    } state_t;

    state_t state = IDLE;

    logic [8*BYTES-1:0] buffer;
    logic [8*MENU_BYTES-1:0] menu_buffer;
    logic [7:0] bytes_left;
    logic [7:0] error_char;
    logic [2:0] hex_position;
    logic welcome_sent = 1'b0;

    logic [47:0] hex_ascii;

    logic overflow_pending;
    logic underflow_pending;

    counter_to_hex hex_converter (
        .counter(counter),
        .ascii_hex(hex_ascii)
    );

    always @(posedge clock) begin
        if (overflow)
            overflow_pending <= 1'b1;
        if (underflow)
            underflow_pending <= 1'b1;
        case (state)
            IDLE: begin
                tx_fifo_wr_en <= 1'b0;
                if (!welcome_sent) begin
                    welcome_sent <= 1'b1;
                    message_type <= MSG_WELCOME;
                    state <= LOAD_MESSAGE;
                end
                else if (btn_inc_pulse) begin
                        message_type <= MSG_BTN_INC;
                        state <= WAIT_COUNTER;
                end
                else if (btn_dec_pulse) begin
                        message_type <= MSG_BTN_DEC;
                        state <= WAIT_COUNTER;
                 end
                 else if (btn_reset_pulse) begin
                        message_type <= MSG_BTN_RESET;
                        state <= WAIT_COUNTER;
                 end
                 else if (inc_command) begin
                        message_type <= MSG_INC;
                        state <= WAIT_COUNTER;
                 end
                 else if (dec_command) begin
                        message_type <= MSG_DEC;
                        state <= WAIT_COUNTER;
                 end
                 else if (reset_command) begin
                        message_type <= MSG_RESET;
                        state <= WAIT_COUNTER;
                 end
                 else if (status_command) begin
                        message_type <= MSG_STATUS;
                        state <= WAIT_COUNTER;
                 end
                 else if (menu_command) begin
                        message_type <= MSG_MENU;
                        state <= WAIT_COUNTER;
                 end
                 else if (error_command) begin
                        error_char <= unknown_command;
                        message_type <= MSG_ERROR;
                        state <= WAIT_COUNTER;
                 end
            end
            WAIT_COUNTER: begin
                    hex_position <= 1'b0;
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
                            menu_buffer <= {"Commands:",8'h0D,8'h0A,"I/i - Increment counter",8'h0D,8'h0A,"D/d - Decrement counter",8'h0D,8'h0A,"R/r - Reset counter",8'h0D,8'h0A,"S/s - Show status",8'h0D,8'h0A,"? - Show menu",8'h0D,8'h0A,{(MENU_BYTES-LEN_MENU){8'h00}}}; 
                            bytes_left <= LEN_MENU;
                            state <= SEND_MENU;
                        end
                        MSG_ERROR: begin
                            buffer <= {"[ERR] Unknown: '",error_char,"'",8'h0D,8'h0A,{(BYTES-LEN_ERROR){8'h00}}}; 
                            bytes_left <= LEN_ERROR;
                            state <= SEND;
                        end
                        MSG_BTN_INC: begin
                            buffer <= {"[BTN] INC | Counter: ",hex_ascii,8'h0D,8'h0A,{(BYTES-LEN_BTN_INC){8'h00}}};
                            bytes_left <= LEN_BTN_INC;
                            state <= SEND;
                        end
                        MSG_BTN_DEC: begin
                            buffer <= {"[BTN] DEC | Counter: ",hex_ascii,8'h0D,8'h0A,{(BYTES-LEN_BTN_DEC){8'h00}}};
                            bytes_left <= LEN_BTN_DEC;
                            state <= SEND;
                        end
                        MSG_BTN_RESET: begin
                            buffer <= {"[BTN] RESET | Counter: ",hex_ascii,8'h0D,8'h0A,{(BYTES-LEN_BTN_RESET){8'h00}}};
                            bytes_left <= LEN_BTN_RESET;
                            state <= SEND;
                        end
                        MSG_OVERFLOW: begin
                            buffer <= {"[SYS] OVERFLOW | Counter: ",hex_ascii,8'h0D,8'h0A,{(BYTES-LEN_OVERFLOW){8'h00}}};
                            bytes_left <= LEN_OVERFLOW;
                            state <= SEND;
                        end
                        MSG_UNDERFLOW: begin
                            buffer <= {"[SYS] UNDERFLOW | Counter: ",hex_ascii,8'h0D,8'h0A,{(BYTES-LEN_UNDERFLOW){8'h00}}};
                            bytes_left <= LEN_UNDERFLOW;
                            state <= SEND;
                        end
                        MSG_WELCOME: begin
                            buffer <= {"[SYS] UART Logger Ready",8'h0D,8'h0A,"[SYS] Type '?' for help",8'h0D,8'h0A,{(BYTES-LEN_WELCOME){8'h00}}};
                            bytes_left <= LEN_WELCOME;
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
                            buffer <= 1'b0;
                            if (overflow_pending) begin
                                overflow_pending <= 1'b0;
                                message_type <= MSG_OVERFLOW;
                                state <= LOAD_MESSAGE;
                            end
                            else if (underflow_pending) begin
                                underflow_pending <= 1'b0;
                                message_type <= MSG_UNDERFLOW;
                                state <= LOAD_MESSAGE;
                            end
                            else begin
                                state <= IDLE;
                            end
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
                            menu_buffer <= 1'b0;
                        end
                    end
            end
            default: begin
                    state <= IDLE;
            end
        endcase
    end
endmodule