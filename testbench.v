/*
    Copyright © 2021 Michal Schulz <michal.schulz@gmx.de>
    https://github.com/michalsc

    This Source Code Form is subject to the terms of the
    Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed
    with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

`include "./bus68020.v"

`timescale 1ns/1ps

module testbench;
 
    reg reset = 'bZ;
    reg clk = 1;
    reg [1:0] dsack = 2'b11;
    wire [31:0] D;

    BUS_68020 V020(
        .nRESET(reset),
        .CLK(clk),
        .nDSACK(dsack),
        .D(D)
    );

    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);

        #5 reset = 0;
        #40 reset = 1;
        #20 V020.r_BReq = 2;
        V020.r_AddrReq = 32'h0123451;
        V020.r_Data = 32'hDEADBEEF;
        V020.r_SizeReq = 0;
        #2 V020.r_BReq = 0;

        #10 dsack = 'b01;
        #2 dsack = 'b11;

        #10 dsack = 'b01;
        #2 dsack = 'b11;

        #10 dsack = 'b01;
        #2 dsack = 'b11;

        #10 dsack = 'b01;
        #2 dsack = 'b11;


        #500 $finish;
    end

    always #1 clk = ~clk;

endmodule
