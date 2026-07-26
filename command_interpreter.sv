`timescale 1ns / 1ps

module command_interpreter(
    input logic clk,
    input logic reset,
    input logic [7:0] received_data,
    input logic data_valid,
    output logic inc_command,
    output logic dec_command,
    output logic reset_command,
    output logic status_command,
    output logic menu_command,
    output logic error_command,
    output logic [7:0] unknown_command
);

always @(posedge clk) begin
    inc_command <= 1'b0;
    dec_command <= 1'b0;
    reset_command <= 1'b0;
    status_command <= 1'b0;
    menu_command <= 1'b0;
    error_command <= 1'b0;
    unknown_command <= 1'b0;
    if (reset == 1) begin
        inc_command <= 1'b0;
        dec_command <= 1'b0;
        reset_command <= 1'b0;
        status_command <= 1'b0;
        menu_command <= 1'b0;
        error_command <= 1'b0;
    end
    else if (data_valid == 1) begin
        case (received_data)
            "I", "i":
                inc_command <= 1'b1;
            "D", "d":
                dec_command <= 1'b1;
            "R", "r":
                reset_command <= 1'b1;
            "S", "s":
                status_command <= 1'b1;
             "?":
                menu_command <= 1'b1;
             default: begin
                error_command <= 1'b1;
                unknown_command <= received_data;
            end
        endcase
    end
end
endmodule