/*
    Copyright © 2021 Michal Schulz <michal.schulz@gmx.de>
    https://github.com/michalsc

    This Source Code Form is subject to the terms of the
    Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed
    with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

localparam op_ADD = 4'b0000;
localparam op_SUB = 4'b0001;
localparam op_ADDX= 4'b0010;
localparam op_SUBX= 4'b0011;
localparam op_AND = 4'b0100;
localparam op_OR  = 4'b0101;
localparam op_EOR = 4'b0110;
localparam op_NOT = 4'b0111;
localparam op_NEG = 4'b1000;
localparam op_NEGX= 4'b1001;
localparam op_SWAP= 4'b1010;
localparam op_EXT = 4'b1011;
localparam op_LSx = 4'b1100;
localparam op_ASx = 4'b1101;
localparam op_ROx = 4'b1110;
localparam op_ROXx= 4'b1111;

localparam shift_LEFT = 1'b0;
localparam shift_RIGHT = 1'b1;

localparam bitpos_X = 4;
localparam bitpos_N = 3;
localparam bitpos_Z = 2;
localparam bitpos_V = 1;
localparam bitpos_C = 0;

localparam BR_NONE = 'd0;
localparam BR_READ = 'd1;
localparam BR_WRITE = 'd2;

localparam SIZ_1 = 'b01;
localparam SIZ_2 = 'b10;
localparam SIZ_3 = 'b11;
localparam SIZ_4 = 'b00;

localparam DSACK_8Bit = 2'b10;
localparam DSACK_16Bit = 2'b01;
localparam DSACK_32Bit = 2'b00;
localparam DSACK_Wait = 2'b11;
