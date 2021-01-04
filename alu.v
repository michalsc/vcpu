
module alu(
    input [1:0] alu_size,
    input [31:0] in_a,
    input [31:0] in_b,
    input [4:0] in_xnzvc,
    input [3:0] alu_sel,

    output [31:0] out_result,
    output [4:0] out_xnzvc
);

    reg [4:0] r_xnzvc;
    reg [32:0] r_result;

    assign out_xnzvc = r_xnzvc;
    assign out_result[31:0] = r_result[31:0];

    parameter size_BYTE = 2'b00;
    parameter size_WORD = 2'b01;
    parameter size_LONG = 2'b10;

    parameter sel_ADD = 4'b0000;

    parameter pos_X = 4;
    parameter pos_N = 3;
    parameter pos_Z = 2;
    parameter pos_V = 1;
    parameter pos_C = 0;

    always @(*)
    begin
        case (alu_sel)
        sel_ADD: begin
            r_result <= {1'b0, in_a} + {1'b0, in_b};
            r_xnzvc[pos_N] <= r_result[31];
            r_xnzvc[pos_C] <= r_result[32];
            r_xnzvc[pos_X] <= r_result[32];
            r_xnzvc[pos_Z] <= r_result[31:0] == 32'b0000000000000000;
            r_xnzvc[pos_V] <= (!in_a[31] & !in_b[31] & r_result[31]) |
                              (in_a[31] & in_b[31] & !r_result[31]);
        end
        endcase
    end


endmodule
