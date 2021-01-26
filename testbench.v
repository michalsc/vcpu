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
    integer i;
    reg [31:0] rom[0:1023];

    reg reset = 'bZ;
    reg clk = 1;
    reg [1:0] dsack = 2'b11;
    reg [31:0] D = 32'bZ;
    reg [31:0] Data;
    reg [31:0] Ain;
    wire as;
    wire ds;
    wire [31:0] A;
    wire RnW;
    reg br = 'b1;
    reg bgack = 'b1;
    reg [2:0] brin;
    wire dben;

    always @(negedge dben) begin
        if (RnW == 'b1) begin
            #40 D[31:0] <= rom[A[31:2]];
            #1 dsack <= 'b00;
        end
    end

    always @(posedge as or posedge ds) begin
        dsack <= 'b11;
        D <= 32'bZ;
    end

    BUS_68020 V020(
        .nRESET(reset),
        .CLK(clk),
        .nDSACK(dsack),
        .D(D),
        .A(A),
        .nBR(br),
        .nBGACK(bgack),
        .nDBEN(dben),
        .RnW(RnW),
        .nAS(as),
        .nDS(ds)
    );

    assign V020.ICache.BRin = brin;
    assign V020.ICache.Ain = Ain;

    initial begin
        $readmemh("rom-aros68k.txt", rom);
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);

        br = 1;
        bgack = 1;

        #5 reset = 0;
        #40 reset = 1;
        #20 

        for (i=0; i < 16; i++) begin
            Ain=i*2;
            brin = 1;
            @(posedge V020.ICache.completed);
            brin = 0;
            #1;
        end
/*
        for (i=0; i < 16; i++) begin
            Ain=i*2;
            brin = 1;
            @(posedge V020.ICache.completed);
            brin = 0;
            #1;
        end

        for (i=0; i < 16; i++) begin
            Ain=i*2;
            brin = 1;
            @(posedge V020.ICache.completed);
            brin = 0;
            #1;
        end
*/
        
/*
        for (i=0; i < 8; i++) begin
            V020.r_BReq = 1;
            V020.r_AddrReq = i;
            V020.r_SizeReq = 'b00;
            #2 V020.r_BReq = 0;
            @(posedge V020.r_BReqComplete);
            Data <= V020.r_Data;
            #5;
        end
*/
        #500 $finish;
    end

    always #1 clk = ~clk;

endmodule
