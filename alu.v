/*
    Copyright © 2021 Michal Schulz <michal.schulz@gmx.de>
    https://github.com/michalsc

    This Source Code Form is subject to the terms of the
    Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed
    with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

`timescale 1ns/1ps

module ALU #(parameter N=8) (
    input           in_CLK,
    input [N-1:0]   in_A,
    input [N-1:0]   in_B,
    input [3:0]     in_OP,
    input           in_X,
    output [N-1:0]  out_RES,
    output [4:0]    out_XNZVC,
    output [4:0]    out_XNZVC_chg
);
    `include "vcpu.vh"

    reg [4:0] r_XNZVC = 5'b0;
    reg [4:0] r_chg_XNZVC = 5'b0;
    reg [N:0] r_X = {N+1{1'b0}};

    assign out_RES = r_X[N-1:0];
    assign out_XNZVC = r_XNZVC;
    assign out_XNZVC_chg = r_chg_XNZVC;

    wire sA = in_OP == op_ASx ? in_A[N-1] : 1'b0;

    always @(posedge in_CLK) begin
        case (in_OP)

            op_ADD: begin
                r_X <= {1'b0, in_A} + {1'b0, in_B};
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_C] <= r_X[N];
                r_XNZVC[bitpos_X] <= r_X[N];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= (!in_A[N-1] & !in_B[N-1] & r_X[N-1]) |
                                     (in_A[N-1] & in_B[N-1] & !r_X[N-1]);
                r_chg_XNZVC <= 5'b11111;
            end

            op_ADDX: begin
                r_X <= {1'b0, in_A} + {1'b0, in_B} + {{N{1'b0}},in_X};
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_C] <= r_X[N];
                r_XNZVC[bitpos_X] <= r_X[N];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= (!in_A[N-1] & !in_B[N-1] & r_X[N-1]) |
                                     (in_A[N-1] & in_B[N-1] & !r_X[N-1]);
                r_chg_XNZVC <= 5'b11111;
            end

            op_SUB: begin
                r_X <= {1'b0, in_A} - {1'b0, in_B};
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_C] <= r_X[N];
                r_XNZVC[bitpos_X] <= r_X[N];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= (!in_A[N-1] & !in_B[N-1] & r_X[N-1]) |
                                     (in_A[N-1] & in_B[N-1] & !r_X[N-1]);
                r_chg_XNZVC <= 5'b11111;
            end

            op_SUBX: begin
                r_X <= {1'b0, in_A} - {1'b0, in_B} - {{N{1'b0}},in_X};
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_C] <= r_X[N];
                r_XNZVC[bitpos_X] <= r_X[N];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= (!in_A[N-1] & !in_B[N-1] & r_X[N-1]) |
                                     (in_A[N-1] & in_B[N-1] & !r_X[N-1]);
                r_chg_XNZVC <= 5'b11111;
            end

            op_NEG: begin
                r_X <= {N+1{1'b0}} - {1'b0, in_A};
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_C] <= r_X[N];
                r_XNZVC[bitpos_X] <= r_X[N];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= (!in_A[N-1] & r_X[N-1]);
                r_chg_XNZVC <= 5'b11111;
            end

            op_NEGX: begin
                r_X <= {N+1{1'b0}} - {1'b0, in_A} - {{N{1'b0}},in_X};
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_C] <= r_X[N];
                r_XNZVC[bitpos_X] <= r_X[N];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= (!in_A[N-1] & r_X[N-1]);
                r_chg_XNZVC <= 5'b11111;
            end

            op_AND: begin
                r_X[31:0] <= in_A & in_B;
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_C] <= 1'b0;
                r_XNZVC[bitpos_V] <= 1'b0;
                r_chg_XNZVC <= 5'b01111;
            end

            op_OR: begin
                r_X[31:0] <= in_A | in_B;
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_C] <= 1'b0;
                r_XNZVC[bitpos_V] <= 1'b0;
                r_chg_XNZVC <= 5'b01111;
            end

            op_EOR: begin
                r_X[31:0] <= in_A ^ in_B;
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_C] <= 1'b0;
                r_XNZVC[bitpos_V] <= 1'b0;
                r_chg_XNZVC <= 5'b01111;
            end

            op_NOT: begin
                r_X[31:0] <= ~in_A;
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_C] <= 1'b0;
                r_XNZVC[bitpos_V] <= 1'b0;
                r_chg_XNZVC <= 5'b01111;
            end

            op_SWAP: if(N==32) begin
                r_X[31:0] <= {in_A[15:0], in_A[31:16]};
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_C] <= 1'b0;
                r_XNZVC[bitpos_V] <= 1'b0;
                r_chg_XNZVC <= 5'b01111;
            end

            op_EXT: if (N==16) begin
                r_X[15:0] <= {{8{in_A[7]}}, in_A[7:0]};
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_C] <= 1'b0;
                r_XNZVC[bitpos_V] <= 1'b0;
                r_chg_XNZVC <= 5'b01111;
            end
            else if (N==32) begin
                if (in_B[0] == 0) begin
                    r_X[31:0] <= {{16{in_A[15]}}, in_A[15:0]};
                end else begin
                    r_X[31:0] <= {{24{in_A[7]}}, in_A[7:0]};
                end
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_C] <= 1'b0;
                r_XNZVC[bitpos_V] <= 1'b0;
                r_chg_XNZVC <= 5'b01111;
            end 

            op_ASx,
            op_LSx: if (N==8) begin
                if (in_B[7] == shift_LEFT) begin
                    case(in_B[5:0])
                        0: begin r_X[7:0] <= in_A[7:0];                                                                          end
                        1: begin r_X[7:0] <= {in_A[6:0], 1'b0};  r_XNZVC[bitpos_C] <= in_A[7];   r_XNZVC[bitpos_X] <= in_A[7];   end
                        2: begin r_X[7:0] <= {in_A[5:0], 2'b0};  r_XNZVC[bitpos_C] <= in_A[6];   r_XNZVC[bitpos_X] <= in_A[6];   end
                        3: begin r_X[7:0] <= {in_A[4:0], 3'b0};  r_XNZVC[bitpos_C] <= in_A[5];   r_XNZVC[bitpos_X] <= in_A[5];   end
                        4: begin r_X[7:0] <= {in_A[3:0], 4'b0};  r_XNZVC[bitpos_C] <= in_A[4];   r_XNZVC[bitpos_X] <= in_A[4];   end
                        5: begin r_X[7:0] <= {in_A[2:0], 5'b0};  r_XNZVC[bitpos_C] <= in_A[3];   r_XNZVC[bitpos_X] <= in_A[3];   end
                        6: begin r_X[7:0] <= {in_A[1:0], 6'b0};  r_XNZVC[bitpos_C] <= in_A[2];   r_XNZVC[bitpos_X] <= in_A[2];   end
                        7: begin r_X[7:0] <= {in_A[0], 7'b0};    r_XNZVC[bitpos_C] <= in_A[1];   r_XNZVC[bitpos_X] <= in_A[1];   end
                        8: begin r_X[7:0] <= 8'b0;               r_XNZVC[bitpos_C] <= in_A[0];   r_XNZVC[bitpos_X] <= in_A[0];   end
                        default: begin
                                 r_X[7:0] <= 8'b0;               r_XNZVC[bitpos_C] <= 1'b0;      r_XNZVC[bitpos_X] <= 1'b0;      end
                    endcase
                end else begin
                    case(in_B[5:0])
                        0: begin r_X[7:0] <= in_A[7:0];                                                                              end
                        1: begin r_X[7:0] <= {{1{sA}}, in_A[7:1]};   r_XNZVC[bitpos_C] <= in_A[0];   r_XNZVC[bitpos_X] <= in_A[0];   end
                        2: begin r_X[7:0] <= {{2{sA}}, in_A[7:2]};   r_XNZVC[bitpos_C] <= in_A[1];   r_XNZVC[bitpos_X] <= in_A[1];   end
                        3: begin r_X[7:0] <= {{3{sA}}, in_A[7:3]};   r_XNZVC[bitpos_C] <= in_A[2];   r_XNZVC[bitpos_X] <= in_A[2];   end
                        4: begin r_X[7:0] <= {{4{sA}}, in_A[7:4]};   r_XNZVC[bitpos_C] <= in_A[3];   r_XNZVC[bitpos_X] <= in_A[3];   end
                        5: begin r_X[7:0] <= {{5{sA}}, in_A[7:5]};   r_XNZVC[bitpos_C] <= in_A[4];   r_XNZVC[bitpos_X] <= in_A[4];   end
                        6: begin r_X[7:0] <= {{6{sA}}, in_A[7:6]};   r_XNZVC[bitpos_C] <= in_A[5];   r_XNZVC[bitpos_X] <= in_A[5];   end
                        7: begin r_X[7:0] <= {{7{sA}}, in_A[7]};     r_XNZVC[bitpos_C] <= in_A[6];   r_XNZVC[bitpos_X] <= in_A[6];   end
                        8: begin r_X[7:0] <= {8{sA}};                r_XNZVC[bitpos_C] <= in_A[7];   r_XNZVC[bitpos_X] <= in_A[7];   end
                        default: begin
                                 r_X[7:0] <= {8{sA}};                r_XNZVC[bitpos_C] <= 1'b0;      r_XNZVC[bitpos_X] <= 1'b0;      end
                    endcase
                end
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= 1'b0;
                if (in_B[5:0] == 0)
                    r_chg_XNZVC <= 5'b01111;
                else
                    r_chg_XNZVC <= 5'b11111;

            end else if (N == 16) begin
                if (in_B[7] == shift_LEFT) begin
                    case(in_B[5:0])
                         0: begin r_X[15:0] <= in_A[15:0];                                                                            end
                         1: begin r_X[15:0] <= {in_A[14:0], 1'b0};    r_XNZVC[bitpos_C] <= in_A[15];  r_XNZVC[bitpos_X] <= in_A[15];  end
                         2: begin r_X[15:0] <= {in_A[13:0], 2'b0};    r_XNZVC[bitpos_C] <= in_A[14];  r_XNZVC[bitpos_X] <= in_A[14];  end
                         3: begin r_X[15:0] <= {in_A[12:0], 3'b0};    r_XNZVC[bitpos_C] <= in_A[13];  r_XNZVC[bitpos_X] <= in_A[13];  end
                         4: begin r_X[15:0] <= {in_A[11:0], 4'b0};    r_XNZVC[bitpos_C] <= in_A[12];  r_XNZVC[bitpos_X] <= in_A[12];  end
                         5: begin r_X[15:0] <= {in_A[10:0], 5'b0};    r_XNZVC[bitpos_C] <= in_A[11];  r_XNZVC[bitpos_X] <= in_A[11];  end
                         6: begin r_X[15:0] <= {in_A[9:0], 6'b0};     r_XNZVC[bitpos_C] <= in_A[10];  r_XNZVC[bitpos_X] <= in_A[10];  end
                         7: begin r_X[15:0] <= {in_A[8:0], 7'b0};     r_XNZVC[bitpos_C] <= in_A[9];   r_XNZVC[bitpos_X] <= in_A[9];   end
                         8: begin r_X[15:0] <= {in_A[7:0], 8'b0};     r_XNZVC[bitpos_C] <= in_A[8];   r_XNZVC[bitpos_X] <= in_A[8];   end
                         9: begin r_X[15:0] <= {in_A[6:0], 9'b0};     r_XNZVC[bitpos_C] <= in_A[7];   r_XNZVC[bitpos_X] <= in_A[7];   end
                        10: begin r_X[15:0] <= {in_A[5:0], 10'b0};    r_XNZVC[bitpos_C] <= in_A[6];   r_XNZVC[bitpos_X] <= in_A[6];   end
                        11: begin r_X[15:0] <= {in_A[4:0], 11'b0};    r_XNZVC[bitpos_C] <= in_A[5];   r_XNZVC[bitpos_X] <= in_A[5];   end
                        12: begin r_X[15:0] <= {in_A[3:0], 12'b0};    r_XNZVC[bitpos_C] <= in_A[4];   r_XNZVC[bitpos_X] <= in_A[4];   end
                        13: begin r_X[15:0] <= {in_A[2:0], 13'b0};    r_XNZVC[bitpos_C] <= in_A[3];   r_XNZVC[bitpos_X] <= in_A[3];   end
                        14: begin r_X[15:0] <= {in_A[1:0], 14'b0};    r_XNZVC[bitpos_C] <= in_A[2];   r_XNZVC[bitpos_X] <= in_A[2];   end
                        15: begin r_X[15:0] <= {in_A[0], 15'b0};      r_XNZVC[bitpos_C] <= in_A[1];   r_XNZVC[bitpos_X] <= in_A[1];   end
                        16: begin r_X[15:0] <= 16'b0;                 r_XNZVC[bitpos_C] <= in_A[0];   r_XNZVC[bitpos_X] <= in_A[0];   end
                        default: begin
                                 r_X[15:0] <= 16'b0;                  r_XNZVC[bitpos_C] <= 1'b0;      r_XNZVC[bitpos_X] <= 1'b0;      end
                    endcase
                end else begin
                    case(in_B[5:0])
                         0: begin r_X[15:0] <= in_A[15:0];                                                                                end
                         1: begin r_X[15:0] <= {{1{sA}}, in_A[15:1]};     r_XNZVC[bitpos_C] <= in_A[0];   r_XNZVC[bitpos_X] <= in_A[0];   end
                         2: begin r_X[15:0] <= {{2{sA}}, in_A[15:2]};     r_XNZVC[bitpos_C] <= in_A[1];   r_XNZVC[bitpos_X] <= in_A[1];   end
                         3: begin r_X[15:0] <= {{3{sA}}, in_A[15:3]};     r_XNZVC[bitpos_C] <= in_A[2];   r_XNZVC[bitpos_X] <= in_A[2];   end
                         4: begin r_X[15:0] <= {{4{sA}}, in_A[15:4]};     r_XNZVC[bitpos_C] <= in_A[3];   r_XNZVC[bitpos_X] <= in_A[3];   end
                         5: begin r_X[15:0] <= {{5{sA}}, in_A[15:5]};     r_XNZVC[bitpos_C] <= in_A[4];   r_XNZVC[bitpos_X] <= in_A[4];   end
                         6: begin r_X[15:0] <= {{6{sA}}, in_A[15:6]};     r_XNZVC[bitpos_C] <= in_A[5];   r_XNZVC[bitpos_X] <= in_A[5];   end
                         7: begin r_X[15:0] <= {{7{sA}}, in_A[15:7]};     r_XNZVC[bitpos_C] <= in_A[6];   r_XNZVC[bitpos_X] <= in_A[6];   end
                         8: begin r_X[15:0] <= {{8{sA}}, in_A[15:8]};     r_XNZVC[bitpos_C] <= in_A[7];   r_XNZVC[bitpos_X] <= in_A[7];   end
                         9: begin r_X[15:0] <= {{9{sA}}, in_A[15:9]};     r_XNZVC[bitpos_C] <= in_A[8];   r_XNZVC[bitpos_X] <= in_A[8];   end
                        10: begin r_X[15:0] <= {{10{sA}}, in_A[15:10]};   r_XNZVC[bitpos_C] <= in_A[9];   r_XNZVC[bitpos_X] <= in_A[9];   end
                        11: begin r_X[15:0] <= {{11{sA}}, in_A[15:11]};   r_XNZVC[bitpos_C] <= in_A[10];  r_XNZVC[bitpos_X] <= in_A[10];  end
                        12: begin r_X[15:0] <= {{12{sA}}, in_A[15:12]};   r_XNZVC[bitpos_C] <= in_A[11];  r_XNZVC[bitpos_X] <= in_A[11];  end
                        13: begin r_X[15:0] <= {{13{sA}}, in_A[15:13]};   r_XNZVC[bitpos_C] <= in_A[12];  r_XNZVC[bitpos_X] <= in_A[12];  end
                        14: begin r_X[15:0] <= {{14{sA}}, in_A[15:14]};   r_XNZVC[bitpos_C] <= in_A[13];  r_XNZVC[bitpos_X] <= in_A[13];  end
                        15: begin r_X[15:0] <= {{15{sA}}, in_A[15]};      r_XNZVC[bitpos_C] <= in_A[14];  r_XNZVC[bitpos_X] <= in_A[14];  end
                        16: begin r_X[15:0] <= {16{sA}};                  r_XNZVC[bitpos_C] <= in_A[15];  r_XNZVC[bitpos_X] <= in_A[15];  end
                        default: begin
                                  r_X[15:0] <= {16{sA}};                  r_XNZVC[bitpos_C] <= 1'b0;      r_XNZVC[bitpos_X] <= 1'b0;      end
                    endcase
                end
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= 1'b0;
                if (in_B[5:0] == 0)
                    r_chg_XNZVC <= 5'b01111;
                else
                    r_chg_XNZVC <= 5'b11111;

            end else begin
                if (in_B[7] == shift_LEFT) begin
                    case(in_B[5:0])
                         0: begin r_X[31:0] <= in_A[31:0];                                                                            end
                         1: begin r_X[31:0] <= {in_A[30:0], 1'b0};    r_XNZVC[bitpos_C] <= in_A[31];  r_XNZVC[bitpos_X] <= in_A[31];  end
                         2: begin r_X[31:0] <= {in_A[29:0], 2'b0};    r_XNZVC[bitpos_C] <= in_A[30];  r_XNZVC[bitpos_X] <= in_A[30];  end
                         3: begin r_X[31:0] <= {in_A[28:0], 3'b0};    r_XNZVC[bitpos_C] <= in_A[29];  r_XNZVC[bitpos_X] <= in_A[29];  end
                         4: begin r_X[31:0] <= {in_A[27:0], 4'b0};    r_XNZVC[bitpos_C] <= in_A[28];  r_XNZVC[bitpos_X] <= in_A[28];  end
                         5: begin r_X[31:0] <= {in_A[26:0], 5'b0};    r_XNZVC[bitpos_C] <= in_A[27];  r_XNZVC[bitpos_X] <= in_A[27];  end
                         6: begin r_X[31:0] <= {in_A[25:0], 6'b0};    r_XNZVC[bitpos_C] <= in_A[26];  r_XNZVC[bitpos_X] <= in_A[26];  end
                         7: begin r_X[31:0] <= {in_A[24:0], 7'b0};    r_XNZVC[bitpos_C] <= in_A[25];  r_XNZVC[bitpos_X] <= in_A[25];  end
                         8: begin r_X[31:0] <= {in_A[23:0], 8'b0};    r_XNZVC[bitpos_C] <= in_A[24];  r_XNZVC[bitpos_X] <= in_A[24];  end
                         9: begin r_X[31:0] <= {in_A[22:0], 9'b0};    r_XNZVC[bitpos_C] <= in_A[23];  r_XNZVC[bitpos_X] <= in_A[23];  end
                        10: begin r_X[31:0] <= {in_A[21:0], 10'b0};   r_XNZVC[bitpos_C] <= in_A[22];  r_XNZVC[bitpos_X] <= in_A[22];  end
                        11: begin r_X[31:0] <= {in_A[20:0], 11'b0};   r_XNZVC[bitpos_C] <= in_A[21];  r_XNZVC[bitpos_X] <= in_A[21];  end
                        12: begin r_X[31:0] <= {in_A[19:0], 12'b0};   r_XNZVC[bitpos_C] <= in_A[20];  r_XNZVC[bitpos_X] <= in_A[20];  end
                        13: begin r_X[31:0] <= {in_A[18:0], 13'b0};   r_XNZVC[bitpos_C] <= in_A[19];  r_XNZVC[bitpos_X] <= in_A[19];  end
                        14: begin r_X[31:0] <= {in_A[17:0], 14'b0};   r_XNZVC[bitpos_C] <= in_A[18];  r_XNZVC[bitpos_X] <= in_A[18];  end
                        15: begin r_X[31:0] <= {in_A[16:0], 15'b0};   r_XNZVC[bitpos_C] <= in_A[17];  r_XNZVC[bitpos_X] <= in_A[17];  end
                        16: begin r_X[31:0] <= {in_A[15:0], 16'b0};   r_XNZVC[bitpos_C] <= in_A[16];  r_XNZVC[bitpos_X] <= in_A[16];  end
                        17: begin r_X[31:0] <= {in_A[14:0], 17'b0};   r_XNZVC[bitpos_C] <= in_A[15];  r_XNZVC[bitpos_X] <= in_A[15];  end
                        18: begin r_X[31:0] <= {in_A[13:0], 18'b0};   r_XNZVC[bitpos_C] <= in_A[14];  r_XNZVC[bitpos_X] <= in_A[14];  end
                        19: begin r_X[31:0] <= {in_A[12:0], 19'b0};   r_XNZVC[bitpos_C] <= in_A[13];  r_XNZVC[bitpos_X] <= in_A[13];  end
                        20: begin r_X[31:0] <= {in_A[11:0], 20'b0};   r_XNZVC[bitpos_C] <= in_A[12];  r_XNZVC[bitpos_X] <= in_A[12];  end
                        21: begin r_X[31:0] <= {in_A[10:0], 21'b0};   r_XNZVC[bitpos_C] <= in_A[11];  r_XNZVC[bitpos_X] <= in_A[11];  end
                        22: begin r_X[31:0] <= {in_A[9:0], 22'b0};    r_XNZVC[bitpos_C] <= in_A[10];  r_XNZVC[bitpos_X] <= in_A[10];  end
                        23: begin r_X[31:0] <= {in_A[8:0], 23'b0};    r_XNZVC[bitpos_C] <= in_A[9];   r_XNZVC[bitpos_X] <= in_A[9];   end
                        24: begin r_X[31:0] <= {in_A[7:0], 24'b0};    r_XNZVC[bitpos_C] <= in_A[8];   r_XNZVC[bitpos_X] <= in_A[8];   end
                        25: begin r_X[31:0] <= {in_A[6:0], 25'b0};    r_XNZVC[bitpos_C] <= in_A[7];   r_XNZVC[bitpos_X] <= in_A[7];   end
                        26: begin r_X[31:0] <= {in_A[5:0], 26'b0};    r_XNZVC[bitpos_C] <= in_A[6];   r_XNZVC[bitpos_X] <= in_A[6];   end
                        27: begin r_X[31:0] <= {in_A[4:0], 27'b0};    r_XNZVC[bitpos_C] <= in_A[5];   r_XNZVC[bitpos_X] <= in_A[5];   end
                        28: begin r_X[31:0] <= {in_A[3:0], 28'b0};    r_XNZVC[bitpos_C] <= in_A[4];   r_XNZVC[bitpos_X] <= in_A[4];   end
                        29: begin r_X[31:0] <= {in_A[2:0], 29'b0};    r_XNZVC[bitpos_C] <= in_A[3];   r_XNZVC[bitpos_X] <= in_A[3];   end
                        30: begin r_X[31:0] <= {in_A[1:0], 30'b0};    r_XNZVC[bitpos_C] <= in_A[2];   r_XNZVC[bitpos_X] <= in_A[2];   end
                        31: begin r_X[31:0] <= {in_A[0], 31'b0};      r_XNZVC[bitpos_C] <= in_A[1];   r_XNZVC[bitpos_X] <= in_A[1];   end
                        32: begin r_X[31:0] <= 32'b0;                 r_XNZVC[bitpos_C] <= in_A[0];   r_XNZVC[bitpos_X] <= in_A[0];   end
                        default: begin
                                 r_X[31:0] <= 32'b0;                  r_XNZVC[bitpos_C] <= 1'b0;      r_XNZVC[bitpos_X] <= 1'b0;      end
                    endcase
                end else begin
                    case(in_B[5:0])
                         0: begin r_X[31:0] <= in_A[31:0];                                                                                end
                         1: begin r_X[31:0] <= {{1{sA}}, in_A[31:1]};     r_XNZVC[bitpos_C] <= in_A[0];   r_XNZVC[bitpos_X] <= in_A[0];   end
                         2: begin r_X[31:0] <= {{2{sA}}, in_A[31:2]};     r_XNZVC[bitpos_C] <= in_A[1];   r_XNZVC[bitpos_X] <= in_A[1];   end
                         3: begin r_X[31:0] <= {{3{sA}}, in_A[31:3]};     r_XNZVC[bitpos_C] <= in_A[2];   r_XNZVC[bitpos_X] <= in_A[2];   end
                         4: begin r_X[31:0] <= {{4{sA}}, in_A[31:4]};     r_XNZVC[bitpos_C] <= in_A[3];   r_XNZVC[bitpos_X] <= in_A[3];   end
                         5: begin r_X[31:0] <= {{5{sA}}, in_A[31:5]};     r_XNZVC[bitpos_C] <= in_A[4];   r_XNZVC[bitpos_X] <= in_A[4];   end
                         6: begin r_X[31:0] <= {{6{sA}}, in_A[31:6]};     r_XNZVC[bitpos_C] <= in_A[5];   r_XNZVC[bitpos_X] <= in_A[5];   end
                         7: begin r_X[31:0] <= {{7{sA}}, in_A[31:7]};     r_XNZVC[bitpos_C] <= in_A[6];   r_XNZVC[bitpos_X] <= in_A[6];   end
                         8: begin r_X[31:0] <= {{8{sA}}, in_A[31:8]};     r_XNZVC[bitpos_C] <= in_A[7];   r_XNZVC[bitpos_X] <= in_A[7];   end
                         9: begin r_X[31:0] <= {{9{sA}}, in_A[31:9]};     r_XNZVC[bitpos_C] <= in_A[8];   r_XNZVC[bitpos_X] <= in_A[8];   end
                        10: begin r_X[31:0] <= {{10{sA}}, in_A[31:10]};   r_XNZVC[bitpos_C] <= in_A[9];   r_XNZVC[bitpos_X] <= in_A[9];   end
                        11: begin r_X[31:0] <= {{11{sA}}, in_A[31:11]};   r_XNZVC[bitpos_C] <= in_A[10];  r_XNZVC[bitpos_X] <= in_A[10];  end
                        12: begin r_X[31:0] <= {{12{sA}}, in_A[31:12]};   r_XNZVC[bitpos_C] <= in_A[11];  r_XNZVC[bitpos_X] <= in_A[11];  end
                        13: begin r_X[31:0] <= {{13{sA}}, in_A[31:13]};   r_XNZVC[bitpos_C] <= in_A[12];  r_XNZVC[bitpos_X] <= in_A[12];  end
                        14: begin r_X[31:0] <= {{14{sA}}, in_A[31:14]};   r_XNZVC[bitpos_C] <= in_A[13];  r_XNZVC[bitpos_X] <= in_A[13];  end
                        15: begin r_X[31:0] <= {{15{sA}}, in_A[31:15]};   r_XNZVC[bitpos_C] <= in_A[14];  r_XNZVC[bitpos_X] <= in_A[14];  end
                        16: begin r_X[31:0] <= {{16{sA}}, in_A[31:16]};   r_XNZVC[bitpos_C] <= in_A[15];  r_XNZVC[bitpos_X] <= in_A[15];  end
                        17: begin r_X[31:0] <= {{17{sA}}, in_A[31:17]};   r_XNZVC[bitpos_C] <= in_A[16];  r_XNZVC[bitpos_X] <= in_A[16];  end
                        18: begin r_X[31:0] <= {{18{sA}}, in_A[31:18]};   r_XNZVC[bitpos_C] <= in_A[17];  r_XNZVC[bitpos_X] <= in_A[17];  end
                        19: begin r_X[31:0] <= {{19{sA}}, in_A[31:19]};   r_XNZVC[bitpos_C] <= in_A[18];  r_XNZVC[bitpos_X] <= in_A[18];  end
                        20: begin r_X[31:0] <= {{20{sA}}, in_A[31:20]};   r_XNZVC[bitpos_C] <= in_A[19];  r_XNZVC[bitpos_X] <= in_A[19];  end
                        21: begin r_X[31:0] <= {{21{sA}}, in_A[31:21]};   r_XNZVC[bitpos_C] <= in_A[20];  r_XNZVC[bitpos_X] <= in_A[20];  end
                        22: begin r_X[31:0] <= {{22{sA}}, in_A[31:22]};   r_XNZVC[bitpos_C] <= in_A[21];  r_XNZVC[bitpos_X] <= in_A[21];  end
                        23: begin r_X[31:0] <= {{23{sA}}, in_A[31:23]};   r_XNZVC[bitpos_C] <= in_A[22];  r_XNZVC[bitpos_X] <= in_A[22];  end
                        24: begin r_X[31:0] <= {{24{sA}}, in_A[31:24]};   r_XNZVC[bitpos_C] <= in_A[23];  r_XNZVC[bitpos_X] <= in_A[23];  end
                        25: begin r_X[31:0] <= {{25{sA}}, in_A[31:25]};   r_XNZVC[bitpos_C] <= in_A[24];  r_XNZVC[bitpos_X] <= in_A[24];  end
                        26: begin r_X[31:0] <= {{26{sA}}, in_A[31:26]};   r_XNZVC[bitpos_C] <= in_A[25];  r_XNZVC[bitpos_X] <= in_A[25];  end
                        27: begin r_X[31:0] <= {{27{sA}}, in_A[31:27]};   r_XNZVC[bitpos_C] <= in_A[26];  r_XNZVC[bitpos_X] <= in_A[26];  end
                        28: begin r_X[31:0] <= {{28{sA}}, in_A[31:28]};   r_XNZVC[bitpos_C] <= in_A[27];  r_XNZVC[bitpos_X] <= in_A[27];  end
                        29: begin r_X[31:0] <= {{29{sA}}, in_A[31:29]};   r_XNZVC[bitpos_C] <= in_A[28];  r_XNZVC[bitpos_X] <= in_A[28];  end
                        30: begin r_X[31:0] <= {{30{sA}}, in_A[31:30]};   r_XNZVC[bitpos_C] <= in_A[29];  r_XNZVC[bitpos_X] <= in_A[29];  end
                        31: begin r_X[31:0] <= {{31{sA}}, in_A[31]};      r_XNZVC[bitpos_C] <= in_A[30];  r_XNZVC[bitpos_X] <= in_A[30];  end
                        32: begin r_X[31:0] <= {32{sA}};                  r_XNZVC[bitpos_C] <= in_A[31];  r_XNZVC[bitpos_X] <= in_A[31];  end
                        default: begin
                                  r_X[31:0] <= {32{sA}};                  r_XNZVC[bitpos_C] <= 1'b0;      r_XNZVC[bitpos_X] <= 1'b0;      end
                    endcase
                end
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= 1'b0;
                if (in_B[5:0] == 0)
                    r_chg_XNZVC <= 5'b01111;
                else
                    r_chg_XNZVC <= 5'b11111;

            end

            op_ROx: if (N == 8) begin
                if (in_B[7] == shift_LEFT) begin
                    case (in_B[5:0])
                        0:                      begin r_X[7:0] <= in_A[7:0];                 r_XNZVC[bitpos_C] <= 1'b0;    end
                        1,9,17,25,33,41,49,57:  begin r_X[7:0] <= {in_A[6:0], in_A[7:7]};    r_XNZVC[bitpos_C] <= in_A[7]; end
                        2,10,18,26,34,42,50,58: begin r_X[7:0] <= {in_A[5:0], in_A[7:6]};    r_XNZVC[bitpos_C] <= in_A[6]; end
                        3,11,19,27,35,43,51,59: begin r_X[7:0] <= {in_A[4:0], in_A[7:5]};    r_XNZVC[bitpos_C] <= in_A[5]; end
                        4,12,20,28,36,44,52,60: begin r_X[7:0] <= {in_A[3:0], in_A[7:4]};    r_XNZVC[bitpos_C] <= in_A[4]; end
                        5,13,21,29,37,45,53,61: begin r_X[7:0] <= {in_A[2:0], in_A[7:3]};    r_XNZVC[bitpos_C] <= in_A[3]; end
                        6,14,22,30,38,46,54,62: begin r_X[7:0] <= {in_A[1:0], in_A[7:2]};    r_XNZVC[bitpos_C] <= in_A[2]; end
                        7,15,23,31,39,47,55,63: begin r_X[7:0] <= {in_A[0:0], in_A[7:1]};    r_XNZVC[bitpos_C] <= in_A[1]; end
                        8,16,24,32,40,48,56:    begin r_X[7:0] <= in_A[7:0];                 r_XNZVC[bitpos_C] <= in_A[0]; end
                    endcase
                end else begin
                    case (in_B[5:0])
                        0:                      begin r_X[7:0] <= in_A[7:0];                 r_XNZVC[bitpos_C] <= 1'b0;    end
                        1,9,17,25,33,41,49,57:  begin r_X[7:0] <= {in_A[0:0], in_A[7:1]};    r_XNZVC[bitpos_C] <= in_A[0]; end
                        2,10,18,26,34,42,50,58: begin r_X[7:0] <= {in_A[1:0], in_A[7:2]};    r_XNZVC[bitpos_C] <= in_A[1]; end
                        3,11,19,27,35,43,51,59: begin r_X[7:0] <= {in_A[2:0], in_A[7:3]};    r_XNZVC[bitpos_C] <= in_A[2]; end
                        4,12,20,28,36,44,52,60: begin r_X[7:0] <= {in_A[3:0], in_A[7:4]};    r_XNZVC[bitpos_C] <= in_A[3]; end
                        5,13,21,29,37,45,53,61: begin r_X[7:0] <= {in_A[4:0], in_A[7:5]};    r_XNZVC[bitpos_C] <= in_A[4]; end
                        6,14,22,30,38,46,54,62: begin r_X[7:0] <= {in_A[5:0], in_A[7:6]};    r_XNZVC[bitpos_C] <= in_A[5]; end
                        7,15,23,31,39,47,55,63: begin r_X[7:0] <= {in_A[6:0], in_A[7:7]};    r_XNZVC[bitpos_C] <= in_A[6]; end
                        8,16,24,32,40,48,56:    begin r_X[7:0] <= in_A[7:0];                 r_XNZVC[bitpos_C] <= in_A[7]; end
                    endcase
                end
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= 1'b0;
                r_chg_XNZVC <= 5'b01111;
            end
            else if (N == 16) begin
                if (in_B[7] == shift_LEFT) begin
                    case (in_B[5:0])
                        0:              begin r_X[15:0] <= in_A[15:0];                r_XNZVC[bitpos_C] <= 1'b0;      end
                        1,17,33,49:     begin r_X[15:0] <= {in_A[14:0], in_A[15:15]}; r_XNZVC[bitpos_C] <= in_A[15];  end
                        2,18,34,50:     begin r_X[15:0] <= {in_A[13:0], in_A[15:14]}; r_XNZVC[bitpos_C] <= in_A[14];  end
                        3,19,35,51:     begin r_X[15:0] <= {in_A[12:0], in_A[15:13]}; r_XNZVC[bitpos_C] <= in_A[13];  end
                        4,20,36,52:     begin r_X[15:0] <= {in_A[11:0], in_A[15:12]}; r_XNZVC[bitpos_C] <= in_A[12];  end
                        5,21,37,53:     begin r_X[15:0] <= {in_A[10:0], in_A[15:11]}; r_XNZVC[bitpos_C] <= in_A[11];  end
                        6,22,38,54:     begin r_X[15:0] <= {in_A[9:0], in_A[15:10]};  r_XNZVC[bitpos_C] <= in_A[10];  end
                        7,23,39,55:     begin r_X[15:0] <= {in_A[8:0], in_A[15:9]};   r_XNZVC[bitpos_C] <= in_A[9];   end
                        8,24,40,56:     begin r_X[15:0] <= {in_A[7:0], in_A[15:8]};   r_XNZVC[bitpos_C] <= in_A[8];   end
                        9,25,41,57:     begin r_X[15:0] <= {in_A[6:0], in_A[15:7]};   r_XNZVC[bitpos_C] <= in_A[7];   end
                        10,26,42,58:    begin r_X[15:0] <= {in_A[5:0], in_A[15:6]};   r_XNZVC[bitpos_C] <= in_A[6];   end
                        11,27,43,59:    begin r_X[15:0] <= {in_A[4:0], in_A[15:5]};   r_XNZVC[bitpos_C] <= in_A[5];   end
                        12,28,44,60:    begin r_X[15:0] <= {in_A[3:0], in_A[15:4]};   r_XNZVC[bitpos_C] <= in_A[4];   end
                        13,29,45,61:    begin r_X[15:0] <= {in_A[2:0], in_A[15:3]};   r_XNZVC[bitpos_C] <= in_A[3];   end
                        14,30,46,62:    begin r_X[15:0] <= {in_A[1:0], in_A[15:2]};   r_XNZVC[bitpos_C] <= in_A[2];   end
                        15,31,47,63:    begin r_X[15:0] <= {in_A[0:0], in_A[15:1]};   r_XNZVC[bitpos_C] <= in_A[1];   end
                        16,32,48:       begin r_X[15:0] <= in_A[15:0];                r_XNZVC[bitpos_C] <= in_A[0];   end
                    endcase
                end else begin
                    case (in_B[5:0])
                        0:              begin r_X[15:0] <= in_A[15:0];                r_XNZVC[bitpos_C] <= 1'b0;      end
                        1,17,33,49:     begin r_X[15:0] <= {in_A[0:0], in_A[15:1]};   r_XNZVC[bitpos_C] <= in_A[0];   end
                        2,18,34,50:     begin r_X[15:0] <= {in_A[1:0], in_A[15:2]};   r_XNZVC[bitpos_C] <= in_A[1];   end
                        3,19,35,51:     begin r_X[15:0] <= {in_A[2:0], in_A[15:3]};   r_XNZVC[bitpos_C] <= in_A[2];   end
                        4,20,36,52:     begin r_X[15:0] <= {in_A[3:0], in_A[15:4]};   r_XNZVC[bitpos_C] <= in_A[3];   end
                        5,21,37,53:     begin r_X[15:0] <= {in_A[4:0], in_A[15:5]};   r_XNZVC[bitpos_C] <= in_A[4];   end
                        6,22,38,54:     begin r_X[15:0] <= {in_A[5:0], in_A[15:6]};   r_XNZVC[bitpos_C] <= in_A[5];   end
                        7,23,39,55:     begin r_X[15:0] <= {in_A[6:0], in_A[15:7]};   r_XNZVC[bitpos_C] <= in_A[6];   end
                        8,24,40,56:     begin r_X[15:0] <= {in_A[7:0], in_A[15:8]};   r_XNZVC[bitpos_C] <= in_A[7];   end
                        9,25,41,57:     begin r_X[15:0] <= {in_A[8:0], in_A[15:9]};   r_XNZVC[bitpos_C] <= in_A[8];   end
                        10,26,42,58:    begin r_X[15:0] <= {in_A[9:0], in_A[15:10]};  r_XNZVC[bitpos_C] <= in_A[9];   end
                        11,27,43,59:    begin r_X[15:0] <= {in_A[10:0], in_A[15:11]}; r_XNZVC[bitpos_C] <= in_A[10];  end
                        12,28,44,60:    begin r_X[15:0] <= {in_A[11:0], in_A[15:12]}; r_XNZVC[bitpos_C] <= in_A[11];  end
                        13,29,45,61:    begin r_X[15:0] <= {in_A[12:0], in_A[15:13]}; r_XNZVC[bitpos_C] <= in_A[12];  end
                        14,30,46,62:    begin r_X[15:0] <= {in_A[13:0], in_A[15:14]}; r_XNZVC[bitpos_C] <= in_A[13];  end
                        15,31,47,63:    begin r_X[15:0] <= {in_A[14:0], in_A[15:15]}; r_XNZVC[bitpos_C] <= in_A[14];  end
                        16,32,48:       begin r_X[15:0] <= in_A[15:0];                r_XNZVC[bitpos_C] <= in_A[15];  end
                    endcase
                end
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= 1'b0;
                r_chg_XNZVC <= 5'b01111;
            end
            else if (N == 32) begin
                if (in_B[7] == shift_LEFT) begin
                    case (in_B[5:0])
                        0:      begin r_X[31:0] <= in_A;                      r_XNZVC[bitpos_C] <= 1'b0;      end
                        1,33:   begin r_X[31:0] <= {in_A[30:0], in_A[31:31]}; r_XNZVC[bitpos_C] <= in_A[31];  end
                        2,34:   begin r_X[31:0] <= {in_A[29:0], in_A[31:30]}; r_XNZVC[bitpos_C] <= in_A[30];  end
                        3,35:   begin r_X[31:0] <= {in_A[28:0], in_A[31:29]}; r_XNZVC[bitpos_C] <= in_A[29];  end
                        4,36:   begin r_X[31:0] <= {in_A[27:0], in_A[31:28]}; r_XNZVC[bitpos_C] <= in_A[28];  end
                        5,37:   begin r_X[31:0] <= {in_A[26:0], in_A[31:27]}; r_XNZVC[bitpos_C] <= in_A[27];  end
                        6,38:   begin r_X[31:0] <= {in_A[25:0], in_A[31:26]}; r_XNZVC[bitpos_C] <= in_A[26];  end
                        7,39:   begin r_X[31:0] <= {in_A[24:0], in_A[31:25]}; r_XNZVC[bitpos_C] <= in_A[25];  end
                        8,40:   begin r_X[31:0] <= {in_A[23:0], in_A[31:24]}; r_XNZVC[bitpos_C] <= in_A[24];  end
                        9,41:   begin r_X[31:0] <= {in_A[22:0], in_A[31:23]}; r_XNZVC[bitpos_C] <= in_A[23];  end
                        10,42:  begin r_X[31:0] <= {in_A[21:0], in_A[31:22]}; r_XNZVC[bitpos_C] <= in_A[22];  end
                        11,43:  begin r_X[31:0] <= {in_A[20:0], in_A[31:21]}; r_XNZVC[bitpos_C] <= in_A[21];  end
                        12,44:  begin r_X[31:0] <= {in_A[19:0], in_A[31:20]}; r_XNZVC[bitpos_C] <= in_A[20];  end
                        13,45:  begin r_X[31:0] <= {in_A[18:0], in_A[31:19]}; r_XNZVC[bitpos_C] <= in_A[19];  end
                        14,46:  begin r_X[31:0] <= {in_A[17:0], in_A[31:18]}; r_XNZVC[bitpos_C] <= in_A[18];  end
                        15,47:  begin r_X[31:0] <= {in_A[16:0], in_A[31:17]}; r_XNZVC[bitpos_C] <= in_A[17];  end
                        16,48:  begin r_X[31:0] <= {in_A[15:0], in_A[31:16]}; r_XNZVC[bitpos_C] <= in_A[16];  end
                        17,49:  begin r_X[31:0] <= {in_A[14:0], in_A[31:15]}; r_XNZVC[bitpos_C] <= in_A[15];  end
                        18,50:  begin r_X[31:0] <= {in_A[13:0], in_A[31:14]}; r_XNZVC[bitpos_C] <= in_A[14];  end
                        19,51:  begin r_X[31:0] <= {in_A[12:0], in_A[31:13]}; r_XNZVC[bitpos_C] <= in_A[13];  end
                        20,52:  begin r_X[31:0] <= {in_A[11:0], in_A[31:12]}; r_XNZVC[bitpos_C] <= in_A[12];  end
                        21,53:  begin r_X[31:0] <= {in_A[10:0], in_A[31:11]}; r_XNZVC[bitpos_C] <= in_A[11];  end
                        22,54:  begin r_X[31:0] <= {in_A[9:0], in_A[31:10]};  r_XNZVC[bitpos_C] <= in_A[10];  end
                        23,55:  begin r_X[31:0] <= {in_A[8:0], in_A[31:9]};   r_XNZVC[bitpos_C] <= in_A[9];   end
                        24,56:  begin r_X[31:0] <= {in_A[7:0], in_A[31:8]};   r_XNZVC[bitpos_C] <= in_A[8];   end
                        25,57:  begin r_X[31:0] <= {in_A[6:0], in_A[31:7]};   r_XNZVC[bitpos_C] <= in_A[7];   end
                        26,58:  begin r_X[31:0] <= {in_A[5:0], in_A[31:6]};   r_XNZVC[bitpos_C] <= in_A[6];   end
                        27,59:  begin r_X[31:0] <= {in_A[4:0], in_A[31:5]};   r_XNZVC[bitpos_C] <= in_A[5];   end
                        28,60:  begin r_X[31:0] <= {in_A[3:0], in_A[31:4]};   r_XNZVC[bitpos_C] <= in_A[4];   end
                        29,61:  begin r_X[31:0] <= {in_A[2:0], in_A[31:3]};   r_XNZVC[bitpos_C] <= in_A[3];   end
                        30,62:  begin r_X[31:0] <= {in_A[1:0], in_A[31:2]};   r_XNZVC[bitpos_C] <= in_A[2];   end
                        31,63:  begin r_X[31:0] <= {in_A[0:0], in_A[31:1]};   r_XNZVC[bitpos_C] <= in_A[1];   end
                        32:     begin r_X[31:0] <= in_A;                      r_XNZVC[bitpos_C] <= in_A[0];   end
                    endcase
                end else begin
                    case (in_B[5:0])
                        0:      begin r_X[31:0] <= in_A;                      r_XNZVC[bitpos_C] <= 1'b0;      end
                        1,33:   begin r_X[31:0] <= {in_A[0:0], in_A[31:1]};   r_XNZVC[bitpos_C] <= in_A[0];   end
                        2,34:   begin r_X[31:0] <= {in_A[1:0], in_A[31:2]};   r_XNZVC[bitpos_C] <= in_A[1];   end
                        3,35:   begin r_X[31:0] <= {in_A[2:0], in_A[31:3]};   r_XNZVC[bitpos_C] <= in_A[2];   end
                        4,36:   begin r_X[31:0] <= {in_A[3:0], in_A[31:4]};   r_XNZVC[bitpos_C] <= in_A[3];   end
                        5,37:   begin r_X[31:0] <= {in_A[4:0], in_A[31:5]};   r_XNZVC[bitpos_C] <= in_A[4];   end
                        6,38:   begin r_X[31:0] <= {in_A[5:0], in_A[31:6]};   r_XNZVC[bitpos_C] <= in_A[5];   end
                        7,39:   begin r_X[31:0] <= {in_A[6:0], in_A[31:7]};   r_XNZVC[bitpos_C] <= in_A[6];   end
                        8,40:   begin r_X[31:0] <= {in_A[7:0], in_A[31:8]};   r_XNZVC[bitpos_C] <= in_A[7];   end
                        9,41:   begin r_X[31:0] <= {in_A[8:0], in_A[31:9]};   r_XNZVC[bitpos_C] <= in_A[8];   end
                        10,42:  begin r_X[31:0] <= {in_A[9:0], in_A[31:10]};  r_XNZVC[bitpos_C] <= in_A[9];   end
                        11,43:  begin r_X[31:0] <= {in_A[10:0], in_A[31:11]}; r_XNZVC[bitpos_C] <= in_A[10];  end
                        12,44:  begin r_X[31:0] <= {in_A[11:0], in_A[31:12]}; r_XNZVC[bitpos_C] <= in_A[11];  end
                        13,45:  begin r_X[31:0] <= {in_A[12:0], in_A[31:13]}; r_XNZVC[bitpos_C] <= in_A[12];  end
                        14,46:  begin r_X[31:0] <= {in_A[13:0], in_A[31:14]}; r_XNZVC[bitpos_C] <= in_A[13];  end
                        15,47:  begin r_X[31:0] <= {in_A[14:0], in_A[31:15]}; r_XNZVC[bitpos_C] <= in_A[14];  end
                        16,48:  begin r_X[31:0] <= {in_A[15:0], in_A[31:16]}; r_XNZVC[bitpos_C] <= in_A[15];  end
                        17,49:  begin r_X[31:0] <= {in_A[16:0], in_A[31:17]}; r_XNZVC[bitpos_C] <= in_A[16];  end
                        18,50:  begin r_X[31:0] <= {in_A[17:0], in_A[31:18]}; r_XNZVC[bitpos_C] <= in_A[17];  end
                        19,51:  begin r_X[31:0] <= {in_A[18:0], in_A[31:19]}; r_XNZVC[bitpos_C] <= in_A[18];  end
                        20,52:  begin r_X[31:0] <= {in_A[19:0], in_A[31:20]}; r_XNZVC[bitpos_C] <= in_A[19];  end
                        21,53:  begin r_X[31:0] <= {in_A[20:0], in_A[31:21]}; r_XNZVC[bitpos_C] <= in_A[20];  end
                        22,54:  begin r_X[31:0] <= {in_A[21:0], in_A[31:22]}; r_XNZVC[bitpos_C] <= in_A[21];  end
                        23,55:  begin r_X[31:0] <= {in_A[22:0], in_A[31:23]}; r_XNZVC[bitpos_C] <= in_A[22];  end
                        24,56:  begin r_X[31:0] <= {in_A[23:0], in_A[31:24]}; r_XNZVC[bitpos_C] <= in_A[23];  end
                        25,57:  begin r_X[31:0] <= {in_A[24:0], in_A[31:25]}; r_XNZVC[bitpos_C] <= in_A[24];  end
                        26,58:  begin r_X[31:0] <= {in_A[25:0], in_A[31:26]}; r_XNZVC[bitpos_C] <= in_A[25];  end
                        27,59:  begin r_X[31:0] <= {in_A[26:0], in_A[31:27]}; r_XNZVC[bitpos_C] <= in_A[26];  end
                        28,60:  begin r_X[31:0] <= {in_A[27:0], in_A[31:28]}; r_XNZVC[bitpos_C] <= in_A[27];  end
                        29,61:  begin r_X[31:0] <= {in_A[28:0], in_A[31:29]}; r_XNZVC[bitpos_C] <= in_A[28];  end
                        30,62:  begin r_X[31:0] <= {in_A[29:0], in_A[31:30]}; r_XNZVC[bitpos_C] <= in_A[29];  end
                        31,63:  begin r_X[31:0] <= {in_A[30:0], in_A[31:31]}; r_XNZVC[bitpos_C] <= in_A[30];  end
                        32:     begin r_X[31:0] <= in_A;                      r_XNZVC[bitpos_C] <= in_A[31];  end
                    endcase
                end
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= 1'b0;
                r_chg_XNZVC <= 5'b01111;
            end
            op_ROXx: if (N == 8) begin
                if (in_B[7] == shift_LEFT) begin
                    case (in_B[5:0])
                        0:                   begin r_X[7:0] <= in_A[7:0];                                           r_XNZVC[bitpos_C] <= in_X;      end
                        1,10,19,28,37,46,55: begin {r_XNZVC[bitpos_X],r_X[7:0]} <= {in_A[7:0], in_X};               r_XNZVC[bitpos_C] <= in_A[7];   end
                        2,11,20,29,38,47,56: begin {r_XNZVC[bitpos_X],r_X[7:0]} <= {in_A[6:0], in_X, in_A[7:7]};    r_XNZVC[bitpos_C] <= in_A[6];   end
                        3,12,21,30,39,48,57: begin {r_XNZVC[bitpos_X],r_X[7:0]} <= {in_A[5:0], in_X, in_A[7:6]};    r_XNZVC[bitpos_C] <= in_A[5];   end
                        4,13,22,31,40,49,58: begin {r_XNZVC[bitpos_X],r_X[7:0]} <= {in_A[4:0], in_X, in_A[7:5]};    r_XNZVC[bitpos_C] <= in_A[4];   end
                        5,14,23,32,41,50,59: begin {r_XNZVC[bitpos_X],r_X[7:0]} <= {in_A[3:0], in_X, in_A[7:4]};    r_XNZVC[bitpos_C] <= in_A[3];   end
                        6,15,24,33,42,51,60: begin {r_XNZVC[bitpos_X],r_X[7:0]} <= {in_A[2:0], in_X, in_A[7:3]};    r_XNZVC[bitpos_C] <= in_A[2];   end
                        7,16,25,34,43,52,61: begin {r_XNZVC[bitpos_X],r_X[7:0]} <= {in_A[1:0], in_X, in_A[7:2]};    r_XNZVC[bitpos_C] <= in_A[1];   end
                        8,17,26,35,44,53,62: begin {r_XNZVC[bitpos_X],r_X[7:0]} <= {in_A[0:0], in_X, in_A[7:1]};    r_XNZVC[bitpos_C] <= in_A[0];   end
                        9,18,27,36,45,54,63: begin {r_XNZVC[bitpos_X],r_X[7:0]} <= {in_X, in_A[7:0]};               r_XNZVC[bitpos_C] <= in_X;      end
                    endcase
                end else begin
                    case (in_B[5:0])
                        0:                   begin r_X[7:0] <= in_A[7:0];                                           r_XNZVC[bitpos_C] <= in_X;      end
                        1,10,19,28,37,46,55: begin {r_X[7:0],r_XNZVC[bitpos_X]} <= {in_X, in_A[7:0]};               r_XNZVC[bitpos_C] <= in_A[0];   end
                        2,11,20,29,38,47,56: begin {r_X[7:0],r_XNZVC[bitpos_X]} <= {in_A[0:0], in_X, in_A[7:1]};    r_XNZVC[bitpos_C] <= in_A[1];   end
                        3,12,21,30,39,48,57: begin {r_X[7:0],r_XNZVC[bitpos_X]} <= {in_A[1:0], in_X, in_A[7:2]};    r_XNZVC[bitpos_C] <= in_A[2];   end
                        4,13,22,31,40,49,58: begin {r_X[7:0],r_XNZVC[bitpos_X]} <= {in_A[2:0], in_X, in_A[7:3]};    r_XNZVC[bitpos_C] <= in_A[3];   end
                        5,14,23,32,41,50,59: begin {r_X[7:0],r_XNZVC[bitpos_X]} <= {in_A[3:0], in_X, in_A[7:4]};    r_XNZVC[bitpos_C] <= in_A[4];   end
                        6,15,24,33,42,51,60: begin {r_X[7:0],r_XNZVC[bitpos_X]} <= {in_A[4:0], in_X, in_A[7:5]};    r_XNZVC[bitpos_C] <= in_A[5];   end
                        7,16,25,34,43,52,61: begin {r_X[7:0],r_XNZVC[bitpos_X]} <= {in_A[5:0], in_X, in_A[7:6]};    r_XNZVC[bitpos_C] <= in_A[6];   end
                        8,17,26,35,44,53,62: begin {r_X[7:0],r_XNZVC[bitpos_X]} <= {in_A[6:0], in_X, in_A[7:7]};    r_XNZVC[bitpos_C] <= in_A[7];   end
                        9,18,27,36,45,54,63: begin {r_X[7:0],r_XNZVC[bitpos_X]} <= {in_A[7:0], in_X};               r_XNZVC[bitpos_C] <= in_X;      end
                    endcase
                end
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= 1'b0;
                if (in_B[5:0] == 0)
                    r_chg_XNZVC <= 5'b01111;
                else
                    r_chg_XNZVC <= 5'b11111;
            end else if (N == 16) begin
                if (in_B[7] == shift_LEFT) begin
                    case (in_B[5:0])
                        0:              begin r_X[15:0] <= in_A[15:0];                                              r_XNZVC[bitpos_C] <= in_X;      end
                        1,18,35,52:     begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[15:0], in_X};                  r_XNZVC[bitpos_C] <= in_A[15];  end
                        2,19,36,53:     begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[14:0], in_X, in_A[15:15]};     r_XNZVC[bitpos_C] <= in_A[14];  end
                        3,20,37,54:     begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[13:0], in_X, in_A[15:14]};     r_XNZVC[bitpos_C] <= in_A[13];  end
                        4,21,38,55:     begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[12:0], in_X, in_A[15:13]};     r_XNZVC[bitpos_C] <= in_A[12];  end
                        5,22,39,56:     begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[11:0], in_X, in_A[15:12]};     r_XNZVC[bitpos_C] <= in_A[11];  end
                        6,23,40,57:     begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[10:0], in_X, in_A[15:11]};     r_XNZVC[bitpos_C] <= in_A[10];  end
                        7,24,41,58:     begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[9:0], in_X, in_A[15:10]};      r_XNZVC[bitpos_C] <= in_A[9];   end
                        8,25,42,59:     begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[8:0], in_X, in_A[15:9]};       r_XNZVC[bitpos_C] <= in_A[8];   end
                        9,26,43,60:     begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[7:0], in_X, in_A[15:8]};       r_XNZVC[bitpos_C] <= in_A[7];   end
                        10,27,44,61:    begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[6:0], in_X, in_A[15:7]};       r_XNZVC[bitpos_C] <= in_A[6];   end
                        11,28,45,62:    begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[5:0], in_X, in_A[15:6]};       r_XNZVC[bitpos_C] <= in_A[5];   end
                        12,29,46,63:    begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[4:0], in_X, in_A[15:5]};       r_XNZVC[bitpos_C] <= in_A[4];   end
                        13,30,47:       begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[3:0], in_X, in_A[15:4]};       r_XNZVC[bitpos_C] <= in_A[3];   end
                        14,31,48:       begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[2:0], in_X, in_A[15:3]};       r_XNZVC[bitpos_C] <= in_A[2];   end
                        15,32,49:       begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[1:0], in_X, in_A[15:2]};       r_XNZVC[bitpos_C] <= in_A[1];   end
                        16,33,50:       begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_A[0:0], in_X, in_A[15:1]};       r_XNZVC[bitpos_C] <= in_A[0];   end
                        17,34,51:       begin {r_XNZVC[bitpos_X],r_X[15:0]} <= {in_X, in_A[15:0]};                  r_XNZVC[bitpos_C] <= in_X;      end
                    endcase
                end else begin
                    case (in_B[5:0])
                        0:              begin r_X[15:0] <= in_A[15:0];                                              r_XNZVC[bitpos_C] <= in_X;      end
                        1,18,35,52:     begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_X, in_A[15:0]};                  r_XNZVC[bitpos_C] <= in_A[0];   end
                        2,19,36,53:     begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[0:0], in_X, in_A[15:1]};       r_XNZVC[bitpos_C] <= in_A[1];   end
                        3,20,37,54:     begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[1:0], in_X, in_A[15:2]};       r_XNZVC[bitpos_C] <= in_A[2];   end
                        4,21,38,55:     begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[2:0], in_X, in_A[15:3]};       r_XNZVC[bitpos_C] <= in_A[3];   end
                        5,22,39,56:     begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[3:0], in_X, in_A[15:4]};       r_XNZVC[bitpos_C] <= in_A[4];   end
                        6,23,40,57:     begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[4:0], in_X, in_A[15:5]};       r_XNZVC[bitpos_C] <= in_A[5];   end
                        7,24,41,58:     begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[5:0], in_X, in_A[15:6]};       r_XNZVC[bitpos_C] <= in_A[6];   end
                        8,25,42,59:     begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[6:0], in_X, in_A[15:7]};       r_XNZVC[bitpos_C] <= in_A[7];   end
                        9,26,43,60:     begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[7:0], in_X, in_A[15:8]};       r_XNZVC[bitpos_C] <= in_A[8];   end
                        10,27,44,61:    begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[8:0], in_X, in_A[15:9]};       r_XNZVC[bitpos_C] <= in_A[9];   end
                        11,28,45,62:    begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[9:0], in_X, in_A[15:10]};      r_XNZVC[bitpos_C] <= in_A[10];  end
                        12,29,46,63:    begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[10:0], in_X, in_A[15:11]};     r_XNZVC[bitpos_C] <= in_A[11];  end
                        13,30,47:       begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[11:0], in_X, in_A[15:12]};     r_XNZVC[bitpos_C] <= in_A[12];  end
                        14,31,48:       begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[12:0], in_X, in_A[15:13]};     r_XNZVC[bitpos_C] <= in_A[13];  end
                        15,32,49:       begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[13:0], in_X, in_A[15:14]};     r_XNZVC[bitpos_C] <= in_A[14];  end
                        16,33,50:       begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[14:0], in_X, in_A[15:15]};     r_XNZVC[bitpos_C] <= in_A[15];  end
                        17,34,51:       begin {r_X[15:0],r_XNZVC[bitpos_X]} <= {in_A[15:0], in_X};                  r_XNZVC[bitpos_C] <= in_X;      end
                    endcase
                end
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= 1'b0;
                if (in_B[5:0] == 0)
                    r_chg_XNZVC <= 5'b01111;
                else
                    r_chg_XNZVC <= 5'b11111;
            end else if (N == 32) begin
                if (in_B[7] == shift_LEFT) begin
                    case (in_B[5:0])
                        0:      begin r_X[31:0] <= in_A;                                                    r_XNZVC[bitpos_C] <= in_X;      end
                        1,34:   begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[31:0], in_X};                  r_XNZVC[bitpos_C] <= in_A[31];  end
                        2,35:   begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[30:0], in_X, in_A[31:31]};     r_XNZVC[bitpos_C] <= in_A[30];  end
                        3,36:   begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[29:0], in_X, in_A[31:30]};     r_XNZVC[bitpos_C] <= in_A[29];  end
                        4,37:   begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[28:0], in_X, in_A[31:29]};     r_XNZVC[bitpos_C] <= in_A[28];  end
                        5,38:   begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[27:0], in_X, in_A[31:28]};     r_XNZVC[bitpos_C] <= in_A[27];  end
                        6,39:   begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[26:0], in_X, in_A[31:27]};     r_XNZVC[bitpos_C] <= in_A[26];  end
                        7,40:   begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[25:0], in_X, in_A[31:26]};     r_XNZVC[bitpos_C] <= in_A[25];  end
                        8,41:   begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[24:0], in_X, in_A[31:25]};     r_XNZVC[bitpos_C] <= in_A[24];  end
                        9,42:   begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[23:0], in_X, in_A[31:24]};     r_XNZVC[bitpos_C] <= in_A[23];  end
                        10,43:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[22:0], in_X, in_A[31:23]};     r_XNZVC[bitpos_C] <= in_A[22];  end
                        11,44:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[21:0], in_X, in_A[31:22]};     r_XNZVC[bitpos_C] <= in_A[21];  end
                        12,45:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[20:0], in_X, in_A[31:21]};     r_XNZVC[bitpos_C] <= in_A[20];  end
                        13,46:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[19:0], in_X, in_A[31:20]};     r_XNZVC[bitpos_C] <= in_A[19];  end
                        14,47:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[18:0], in_X, in_A[31:19]};     r_XNZVC[bitpos_C] <= in_A[18];  end
                        15,48:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[17:0], in_X, in_A[31:18]};     r_XNZVC[bitpos_C] <= in_A[17];  end
                        16,49:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[16:0], in_X, in_A[31:17]};     r_XNZVC[bitpos_C] <= in_A[16];  end
                        17,50:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[15:0], in_X, in_A[31:16]};     r_XNZVC[bitpos_C] <= in_A[15];  end
                        18,51:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[14:0], in_X, in_A[31:15]};     r_XNZVC[bitpos_C] <= in_A[14];  end
                        19,52:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[13:0], in_X, in_A[31:14]};     r_XNZVC[bitpos_C] <= in_A[13];  end
                        20,53:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[12:0], in_X, in_A[31:13]};     r_XNZVC[bitpos_C] <= in_A[12];  end
                        21,54:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[11:0], in_X, in_A[31:12]};     r_XNZVC[bitpos_C] <= in_A[11];  end
                        22,55:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[10:0], in_X, in_A[31:11]};     r_XNZVC[bitpos_C] <= in_A[10];  end
                        23,56:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[9:0], in_X, in_A[31:10]};      r_XNZVC[bitpos_C] <= in_A[9];   end
                        24,57:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[8:0], in_X, in_A[31:9]};       r_XNZVC[bitpos_C] <= in_A[8];   end
                        25,58:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[7:0], in_X, in_A[31:8]};       r_XNZVC[bitpos_C] <= in_A[7];   end
                        26,59:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[6:0], in_X, in_A[31:7]};       r_XNZVC[bitpos_C] <= in_A[6];   end
                        27,60:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[5:0], in_X, in_A[31:6]};       r_XNZVC[bitpos_C] <= in_A[5];   end
                        28,61:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[4:0], in_X, in_A[31:5]};       r_XNZVC[bitpos_C] <= in_A[4];   end
                        29,62:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[3:0], in_X, in_A[31:4]};       r_XNZVC[bitpos_C] <= in_A[3];   end
                        30,63:  begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[2:0], in_X, in_A[31:3]};       r_XNZVC[bitpos_C] <= in_A[2];   end
                        31:     begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[1:0], in_X, in_A[31:2]};       r_XNZVC[bitpos_C] <= in_A[1];   end
                        32:     begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_A[0:0], in_X, in_A[31:1]};       r_XNZVC[bitpos_C] <= in_A[0];   end
                        33:     begin {r_XNZVC[bitpos_X],r_X[31:0]} <= {in_X, in_A[31:0]};                  r_XNZVC[bitpos_C] <= in_X;      end
                    endcase
                end else begin
                    case (in_B[5:0])
                        0:      begin r_X[31:0] <= in_A;                                                   r_XNZVC[bitpos_C] <= in_X;       end
                        1,34:   begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_X, in_A[31:0]};                 r_XNZVC[bitpos_C] <= in_A[0];    end
                        2,35:   begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[0:0], in_X, in_A[31:1]};      r_XNZVC[bitpos_C] <= in_A[1];    end
                        3,36:   begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[1:0], in_X, in_A[31:2]};      r_XNZVC[bitpos_C] <= in_A[2];    end
                        4,37:   begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[2:0], in_X, in_A[31:3]};      r_XNZVC[bitpos_C] <= in_A[3];    end
                        5,38:   begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[3:0], in_X, in_A[31:4]};      r_XNZVC[bitpos_C] <= in_A[4];    end
                        6,39:   begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[4:0], in_X, in_A[31:5]};      r_XNZVC[bitpos_C] <= in_A[5];    end
                        7,40:   begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[5:0], in_X, in_A[31:6]};      r_XNZVC[bitpos_C] <= in_A[6];    end
                        8,41:   begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[6:0], in_X, in_A[31:7]};      r_XNZVC[bitpos_C] <= in_A[7];    end
                        9,42:   begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[7:0], in_X, in_A[31:8]};      r_XNZVC[bitpos_C] <= in_A[8];    end
                        10,43:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[8:0], in_X, in_A[31:9]};      r_XNZVC[bitpos_C] <= in_A[9];    end
                        11,44:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[9:0], in_X, in_A[31:10]};     r_XNZVC[bitpos_C] <= in_A[10];   end
                        12,45:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[10:0], in_X, in_A[31:11]};    r_XNZVC[bitpos_C] <= in_A[11];   end
                        13,46:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[11:0], in_X, in_A[31:12]};    r_XNZVC[bitpos_C] <= in_A[12];   end
                        14,47:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[12:0], in_X, in_A[31:13]};    r_XNZVC[bitpos_C] <= in_A[13];   end
                        15,48:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[13:0], in_X, in_A[31:14]};    r_XNZVC[bitpos_C] <= in_A[14];   end
                        16,49:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[14:0], in_X, in_A[31:15]};    r_XNZVC[bitpos_C] <= in_A[15];   end
                        17,50:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[15:0], in_X, in_A[31:16]};    r_XNZVC[bitpos_C] <= in_A[16];   end
                        18,51:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[16:0], in_X, in_A[31:17]};    r_XNZVC[bitpos_C] <= in_A[17];   end
                        19,52:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[17:0], in_X, in_A[31:18]};    r_XNZVC[bitpos_C] <= in_A[18];   end
                        20,53:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[18:0], in_X, in_A[31:19]};    r_XNZVC[bitpos_C] <= in_A[19];   end
                        21,54:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[19:0], in_X, in_A[31:20]};    r_XNZVC[bitpos_C] <= in_A[20];   end
                        22,55:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[20:0], in_X, in_A[31:21]};    r_XNZVC[bitpos_C] <= in_A[21];   end
                        23,56:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[21:0], in_X, in_A[31:22]};    r_XNZVC[bitpos_C] <= in_A[22];   end
                        24,57:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[22:0], in_X, in_A[31:23]};    r_XNZVC[bitpos_C] <= in_A[23];   end
                        25,58:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[23:0], in_X, in_A[31:24]};    r_XNZVC[bitpos_C] <= in_A[24];   end
                        26,59:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[24:0], in_X, in_A[31:25]};    r_XNZVC[bitpos_C] <= in_A[25];   end
                        27,60:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[25:0], in_X, in_A[31:26]};    r_XNZVC[bitpos_C] <= in_A[26];   end
                        28,61:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[26:0], in_X, in_A[31:27]};    r_XNZVC[bitpos_C] <= in_A[27];   end
                        29,62:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[27:0], in_X, in_A[31:28]};    r_XNZVC[bitpos_C] <= in_A[28];   end
                        30,63:  begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[28:0], in_X, in_A[31:29]};    r_XNZVC[bitpos_C] <= in_A[29];   end
                        31:     begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[29:0], in_X, in_A[31:30]};    r_XNZVC[bitpos_C] <= in_A[30];   end
                        32:     begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[30:0], in_X, in_A[31:31]};    r_XNZVC[bitpos_C] <= in_A[31];   end
                        33:     begin {r_X[31:0],r_XNZVC[bitpos_X]} <= {in_A[31:0], in_X};                 r_XNZVC[bitpos_C] <= in_X;       end
                    endcase
                end
                r_XNZVC[bitpos_N] <= r_X[N-1];
                r_XNZVC[bitpos_Z] <= r_X[N-1:0] == {N{1'b0}};
                r_XNZVC[bitpos_V] <= 1'b0;
                if (in_B[5:0] == 0)
                    r_chg_XNZVC <= 5'b01111;
                else
                    r_chg_XNZVC <= 5'b11111;
            end


        endcase
    end

endmodule
