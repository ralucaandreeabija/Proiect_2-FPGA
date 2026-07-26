`timescale 1ns / 1ps

module counter_to_hex(
    input logic [15:0] counter,
    input logic [2:0] position,
    output logic [7:0] ascii_char
);

    always @(*) begin

        case (position)

            3'd0:
                ascii_char = "0";

            3'd1:
                ascii_char = "x";

            3'd2: begin
                if (counter[15:12] < 10)
                    ascii_char = 8'h30 + counter[15:12];
                else
                    ascii_char = 8'h37 + counter[15:12];
            end

            3'd3: begin
                if (counter[11:8] < 10)
                    ascii_char = 8'h30 + counter[11:8];
                else
                    ascii_char = 8'h37 + counter[11:8];
            end

            3'd4: begin
                if (counter[7:4] < 10)
                    ascii_char = 8'h30 + counter[7:4];
                else
                    ascii_char = 8'h37 + counter[7:4];
            end

            3'd5: begin
                if (counter[3:0] < 10)
                    ascii_char = 8'h30 + counter[3:0];
                else
                    ascii_char = 8'h37 + counter[3:0];
            end

            default:
                ascii_char = 8'h00;

        endcase

    end

endmodule