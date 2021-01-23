/*
    Copyright © 2021 Michal Schulz <michal.schulz@gmx.de>
    https://github.com/michalsc

    This Source Code Form is subject to the terms of the
    Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed
    with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

`timescale 1ns/1ps
`include "./vcpu.v"
`include "./cache.v"

module BUS_68020(
    output [2:0]    FC,     // Function codes, three-state
    output [31:0]   A,      // Address bus, three-state
    input /*inout*/ [31:0]    D,      // Data bus, three-state
    output [1:0]    SIZ,    // Transfer size, three-state
    input           nCDIS,  // Emulator support

    /* Asynchronous bus control */
    output          nOCS,   // operand cycle start
    output          nECS,   // external cycle start
    output          RnW,    // read/write, three-state
    output          nRMC,   // read/modify/write cycle, three-state
    output          nAS,    // Address bus strobe, three-state
    output          nDS,    // Data bus strobe, three-state
    output          nDBEN,  // Data bus enable
    input [1:0]     nDSACK, // Data transfer and size ACK

    input /*inout*/           nRESET, // System reset
    inout           nHALT,  // Halt
    input           nBERR,  // Bus error

    input           nBR,    // Bus request
    output          nBG,    // Bus grant
    input           nBGACK, // Bus grant ACK

    input [2:0]     nIPL,   // Interrupt priority level
    output          nIPEND, // Interrupt pending
    input           nAVEC,  // Autovector

    input           CLK     // Input clock
);

    wire in_RESET;
    wire out_RESET = 1;

    reg [31:0] r_D;
    reg [31:0] r_A;
    reg [2:0] r_FC;
    reg r_IPEND;
    reg r_BG;
    reg [1:0] r_SIZ;

    reg r_OCS;
    reg r_ECS;
    reg r_RnW;
    reg r_RMC;
    reg r_AS;
    reg r_DS;
    reg r_DBEN;
    reg r_AltDBEN;

    assign FC = r_FC;
    assign D = r_D;
    assign A = r_A;
    assign SIZ = r_SIZ;
    
    assign nOCS = r_OCS | CLK;
    assign nECS = r_ECS | CLK;
    assign RnW = r_RnW;
    assign nRMC = r_RMC;
    assign nAS = (r_BusState == BS_GRANTED || r_BusState == BS_GRANTING|| r_BusState == BS_RESET) ? 'bZ : r_AS;
    assign nDS = (r_BusState == BS_GRANTED || r_BusState == BS_GRANTING|| r_BusState == BS_RESET) ? 'bZ : r_DS;
    assign nDBEN = (r_BusState == BS_GRANTED || r_BusState == BS_GRANTING|| r_BusState == BS_RESET) ? 'bZ : (r_DBEN & r_AltDBEN);

    assign nBG = r_BG;
    assign nIPEND = r_IPEND;

    assign nRESET = (out_RESET == 1) ? 1'bZ: 1'b0;
    assign in_RESET = (out_RESET == 1) ? nRESET : 1'b1; 

    INSNCache ICache(
        .CLK(CLK),
        .nRESET(in_RESET),
        .Ain(r_AddrReq),
        .BR(r_BReq)
    );

    DATACache DCache(
        .CLK(CLK)
    );

    VCPU VCore(
        .in_CLK(CLK),
        .in_RESET(in_RESET),
        .out_RESET(out_RESET)
    );

    reg [4:0] r_BusState = 'd0;
    reg [4:0] r_BusAltState = 'd0;
    reg [7:0] r_Delay;
    reg r_BReqComplete = 'd0;
    reg [2:0] r_BReq = 'd0;
    reg [31:0] r_Data = 'd0;
    reg [31:0] r_AddrReq = 'd0;
    reg [2:0] r_FCReq = 'd0;
    reg [1:0] r_SizeReq = 'd0;
    reg [1:0] r_DSACK = 'b0;
    reg r_Latched;
    reg [31:0] r_LatchData;
    reg [31:0] r_ATmp;

    parameter SIZ_1 = 'b01;
    parameter SIZ_2 = 'b10;
    parameter SIZ_3 = 'b11;
    parameter SIZ_4 = 'b00;

    parameter BR_NONE = 'd0;
    parameter BR_READ = 'd1;
    parameter BR_WRITE = 'd2;

    parameter BS_IDLE = 5'd00;
    parameter BS_RESET = 5'd01;
    parameter BS_READ_S0 = 5'd02;
    parameter BS_READ_S2 = 5'd03;
    parameter BS_READ_S4 = 5'd04;
    parameter BS_READ_S1 = 5'd02;
    parameter BS_READ_S3 = 5'd03;
    parameter BS_READ_S5 = 5'd04;

    parameter BS_WRITE_S0 = 5'd05;
    parameter BS_WRITE_S2 = 5'd06;
    parameter BS_WRITE_S4 = 5'd07;
    parameter BS_WRITE_S1 = 5'd05;
    parameter BS_WRITE_S3 = 5'd06;
    parameter BS_WRITE_S5 = 5'd07;

    parameter BS_GRANTING = 5'd08;
    parameter BS_GRANTED = 5'd09;


    parameter DSACK_8Bit = 2'b10;
    parameter DSACK_16Bit = 2'b01;
    parameter DSACK_32Bit = 2'b00;
    parameter DSACK_Wait = 2'b11;

    always @(posedge CLK) begin
        
        if (in_RESET == 0) begin
            if (r_BusState != BS_RESET) begin
                r_BusState <= BS_RESET;
                r_BusAltState <= BS_RESET;

                r_FC <= 3'bZZZ;
                r_A <= {32{1'bZ}};
                r_D <= {32{1'bZ}};
                r_SIZ <= 2'bZ;

                r_OCS <= 1'b1;
                r_ECS <= 1'b1;
                r_RnW <= 1'bZ;
                r_RMC <= 1'bZ;
                r_DBEN <= 1'b1;
                r_AltDBEN <= 1'b1;

                r_BG <= 'b1;
                r_IPEND <= 'b1;
                r_Delay <= 'd4;
            end
        end 
        else begin
            case (r_BusState)
            
            BS_RESET: begin
                if (r_Delay > 0) begin
                    r_Delay <= r_Delay - 'd1;
                end 
                else begin
                    r_BusState <= BS_IDLE;
                    r_BusAltState <= BS_IDLE;
                end
            end

            BS_GRANTING: begin
                r_BG <= 'b0;
                if (nBGACK == 'b0) begin
                    r_Delay <= 'd1;
                    r_BusState <= BS_GRANTED;
                    r_BusAltState <= BS_GRANTED;
                end
                else if (nBR == 'b1) begin
                    r_BusState <= BS_IDLE;
                    r_BusAltState <= BS_IDLE;
                end
            end

            BS_GRANTED: begin
                if (r_Delay == 0) begin
                    r_BG <= 'b1;
                    if (nBR == 'b0) 
                        r_BG <= 'b0;
                end
                else
                    r_Delay <= r_Delay - 'b1;
                

                if (nBGACK != 'b0) begin
                    r_BusState <= BS_IDLE;
                    r_BusAltState <= BS_IDLE;
                end
            end

            BS_IDLE: begin
                r_FC <= 'bZZZ;
                r_BReqComplete <= 'b0;
                if (nBR == 0) begin
                    r_BusAltState <= BS_GRANTING;
                    r_BusState <= BS_GRANTING;
                    r_FC <= 3'bZZZ;
                    r_A <= {32{1'bZ}};
                    r_D <= {32{1'bZ}};
                    r_SIZ <= 2'bZ;
                    r_RnW <= 1'bZ;
                end else begin
                    r_DBEN <= 'b1;
                    if (r_BReq == BR_READ) begin
                        /* BS_READ_S0 */
                        r_OCS <= 'b0;
                        r_ECS <= 'b0;
                        r_A <= r_AddrReq;
                        r_FC <= r_FCReq;
                        r_ATmp <= r_AddrReq;
                        r_RnW <= 'b1;
                        r_BusState <= BS_READ_S2;
                        r_BusAltState <= BS_READ_S1;
                        r_SIZ <= r_SizeReq;
                    end
                    else if (r_BReq == BR_WRITE) begin
                        /* BS_READ_S0 */
                        r_OCS <= 'b0;
                        r_ECS <= 'b0;
                        r_A <= r_AddrReq;
                        r_FC <= r_FCReq;
                        r_ATmp <= r_AddrReq;
                        r_RnW <= 'b0;
                        r_BusState <= BS_WRITE_S2;
                        r_BusAltState <= BS_WRITE_S1;
                        r_SIZ <= r_SizeReq;
                    end
                    else r_BusAltState <= BS_IDLE;
                end
            end

            BS_READ_S0: begin
                r_ECS <= 'b0;
                r_RnW <= 'b1;
                r_DBEN <= 'b1;
                r_A <= r_ATmp;
                r_FC <= r_FCReq;
                r_BusState <= BS_READ_S2;
                r_BusAltState <= BS_READ_S1;
            end

            BS_READ_S2: begin
                r_DBEN <= 1'b0;
                r_OCS <= 1'b1;
                r_ECS <= 1'b1;
                r_BusState <= BS_READ_S4;
                r_BusAltState <= BS_READ_S3;
            end

            BS_READ_S4: begin
                r_DBEN <= 'b1;
                if (r_Latched) begin
                    case (r_SIZ)
                        SIZ_4: begin
                            if (nDSACK == DSACK_32Bit) begin
                                if (A[1:0] == 2'b00) begin
                                    r_Data <= r_LatchData;
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else if (A[1:0] == 2'b01) begin
                                    r_Data[31:8] <= r_LatchData[23:0];
                                    r_SIZ <= SIZ_1;
                                    r_ATmp <= r_ATmp + 3;
                                    r_BusState <= BS_READ_S0;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else if (A[1:0] == 2'b10) begin
                                    r_Data[31:16] <= r_LatchData[15:0];
                                    r_SIZ <= SIZ_2;
                                    r_ATmp <= r_ATmp + 2;
                                    r_BusState <= BS_READ_S0;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else begin
                                    r_Data[31:24] <= r_LatchData[7:0];
                                    r_SIZ <= SIZ_3;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_READ_S0;
                                    r_BusAltState <= BS_READ_S5;
                                end
                            end
                            else if (nDSACK == DSACK_16Bit) begin
                                if (A[0] == 0) begin
                                    r_Data[31:16] <= r_LatchData[31:16];
                                    r_SIZ <= SIZ_2;
                                    r_ATmp <= r_ATmp + 2;
                                    r_BusState <= BS_READ_S0;
                                    r_BusAltState <= BS_READ_S5;
                                end else begin
                                    r_Data[31:24] <= r_LatchData[23:16];
                                    r_SIZ <= SIZ_3;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_READ_S0;
                                    r_BusAltState <= BS_READ_S5;
                                end
                            end
                            else begin
                                r_Data[31:24] <= r_LatchData[31:24];
                                r_SIZ <= SIZ_3;
                                r_ATmp <= r_ATmp + 1;
                                r_BusState <= BS_READ_S0;
                                r_BusAltState <= BS_READ_S5;
                            end
                        end
                        SIZ_3: begin
                            if (nDSACK == DSACK_32Bit) begin
                                if (A[1:0] == 2'b00) begin
                                    r_Data[23:0] <= r_LatchData[31:8];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else if (A[1:0] == 2'b01) begin
                                    r_Data[23:0] <= r_LatchData[23:0];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else if (A[1:0] == 2'b10) begin
                                    r_Data[23:8] <= r_LatchData[15:0];
                                    r_SIZ <= SIZ_1;
                                    r_ATmp <= r_ATmp + 2;
                                    r_BusState <= BS_READ_S0;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else begin
                                    r_Data[23:16] <= r_LatchData[7:0];
                                    r_SIZ <= SIZ_2;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_READ_S0;
                                    r_BusAltState <= BS_READ_S5;
                                end
                            end
                            else if (nDSACK == DSACK_16Bit) begin
                                if (A[0] == 0) begin
                                    r_Data[23:8] <= r_LatchData[31:16];
                                    r_SIZ <= SIZ_1;
                                    r_ATmp <= r_ATmp + 2;
                                    r_BusState <= BS_READ_S0;
                                    r_BusAltState <= BS_READ_S5;
                                end else begin
                                    r_Data[23:16] <= r_LatchData[23:16];
                                    r_SIZ <= SIZ_2;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_READ_S0;
                                    r_BusAltState <= BS_READ_S5;
                                end
                            end
                            else begin
                                r_Data[23:16] <= r_LatchData[31:24];
                                r_SIZ <= SIZ_2;
                                r_ATmp <= r_ATmp + 1;
                                r_BusState <= BS_READ_S0;
                                r_BusAltState <= BS_READ_S5;
                            end
                        end
                        SIZ_2: begin
                            if (nDSACK == DSACK_32Bit) begin
                                if (A[1:0] == 2'b00) begin
                                    r_Data[15:0] <= r_LatchData[31:16];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else if (A[1:0] == 2'b01) begin
                                    r_Data[15:0] <= r_LatchData[23:8];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else if (A[1:0] == 2'b10) begin
                                    r_Data[15:0] <= r_LatchData[15:0];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else begin
                                    r_Data[15:8] <= r_LatchData[7:0];
                                    r_SIZ <= SIZ_1;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_READ_S0;
                                    r_BusAltState <= BS_READ_S5;
                                end
                            end
                            else if (nDSACK == DSACK_16Bit) begin
                                if (A[0] == 0) begin
                                    r_Data[15:0] <= r_LatchData[31:16];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end else begin
                                    r_Data[15:8] <= r_LatchData[23:16];
                                    r_SIZ <= SIZ_1;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_READ_S0;
                                    r_BusAltState <= BS_READ_S5;
                                end
                            end
                            else begin
                                r_Data[15:8] <= r_LatchData[31:24];
                                r_SIZ <= SIZ_1;
                                r_ATmp <= r_ATmp + 1;
                                r_BusState <= BS_READ_S0;
                                r_BusAltState <= BS_READ_S5;
                            end
                        end
                        SIZ_1: begin
                            if (nDSACK == DSACK_32Bit) begin
                                if (A[1:0] == 2'b00) begin
                                    r_Data[7:0] <= r_LatchData[31:24];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else if (A[1:0] == 2'b01) begin
                                    r_Data[7:0] <= r_LatchData[23:16];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else if (A[1:0] == 2'b10) begin
                                    r_Data[7:0] <= r_LatchData[15:8];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end
                                else begin
                                    r_Data[7:0] <= r_LatchData[7:0];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end
                            end
                            else if (nDSACK == DSACK_16Bit) begin
                                if (A[0] == 0) begin
                                    r_Data[7:0] <= r_LatchData[31:24];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end else begin
                                    r_Data[7:0] <= r_LatchData[23:16];
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_READ_S5;
                                end
                            end
                            else begin
                                r_Data[7:0] <= r_LatchData[31:24];
                                r_BReqComplete <= 'b1;
                                r_BusState <= BS_IDLE;
                                r_BusAltState <= BS_READ_S5;
                            end
                        end
                    endcase
                end
            end

            BS_WRITE_S0: begin
                r_ECS <= 'b0;
                r_RnW <= 'b0;
                r_DBEN <= 'b1;
                r_A <= r_ATmp;
                r_BusState <= BS_WRITE_S2;
                r_BusAltState <= BS_WRITE_S1;
            end

            BS_WRITE_S2: begin
                r_OCS <= 1'b1;
                r_ECS <= 1'b1;
                r_DBEN <= 'b0;
                r_BusState <= BS_WRITE_S4;
                r_BusAltState <= BS_WRITE_S3;

                case (r_SIZ)
                    SIZ_1: r_D <= { r_Data[7:0], r_Data[7:0], r_Data[7:0], r_Data[7:0] };
                    SIZ_2: begin
                        if (r_A[0] == 'b0)
                            r_D <= { r_Data[15:0], r_Data[15:0] };
                        else
                            r_D <= { r_Data[15:8], r_Data[15:8], r_Data[7:0], r_Data[15:8] };
                    end
                    SIZ_3: begin
                        if (r_A[1:0] == 'b00)
                            r_D <= { r_Data[23:0], r_Data[31:24] };
                        else if (r_A[1:0] == 'b01)
                            r_D <= { r_Data[23:16], r_Data[23:0] };
                        else if (r_A[1:0] == 'b10)
                            r_D <= { r_Data[23:8], r_Data[23:8] };
                        else
                            r_D <= { r_Data[23:16], r_Data[23:16], r_Data[15:8], r_Data[23:16] };
                    end
                    SIZ_4: begin
                        if (r_A[1:0] == 'b00)
                            r_D <= r_Data;
                        else if (r_A[1:0] == 'b01)
                            r_D <= { r_Data[31:24], r_Data[31:8] };
                        else if (r_A[1:0] == 'b10)
                            r_D <= { r_Data[31:16], r_Data[31:16] };
                        else
                            r_D <= { r_Data[31:24], r_Data[31:24], r_Data[23:16], r_Data[31:24] };
                    end
                endcase
            end

            BS_WRITE_S4: begin
                if (r_Latched) begin
                    case (r_SIZ)
                        SIZ_4: begin
                            if (nDSACK == DSACK_32Bit) begin
                                if (A[1:0] == 2'b00) begin
                                    r_BReqComplete <= 'b1;
                                    r_BusState <= BS_IDLE;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                                else if (A[1:0] == 2'b01) begin
                                    r_SIZ <= SIZ_1;
                                    r_ATmp <= r_ATmp + 3;
                                    r_BusState <= BS_WRITE_S0;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                                else if (A[1:0] == 2'b10) begin
                                    r_SIZ <= SIZ_2;
                                    r_ATmp <= r_ATmp + 2;
                                    r_BusState <= BS_WRITE_S0;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                                else begin
                                    r_SIZ <= SIZ_3;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_WRITE_S0;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                            end
                            else if (nDSACK == DSACK_16Bit) begin
                                if (A[0] == 0) begin
                                    r_SIZ <= SIZ_2;
                                    r_ATmp <= r_ATmp + 2;
                                    r_BusState <= BS_WRITE_S0;
                                    r_BusAltState <= BS_WRITE_S5;
                                end else begin
                                    r_SIZ <= SIZ_3;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_WRITE_S0;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                            end
                            else begin
                                r_SIZ <= SIZ_3;
                                r_ATmp <= r_ATmp + 1;
                                r_BusState <= BS_WRITE_S0;
                                r_BusAltState <= BS_WRITE_S5;
                            end
                        end
                        SIZ_3: begin
                            if (nDSACK == DSACK_32Bit) begin
                                if (A[1:0] == 2'b00) begin
                                    r_BusState <= BS_IDLE;
                                    r_BReqComplete <= 'b1;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                                else if (A[1:0] == 2'b01) begin
                                    r_BusState <= BS_IDLE;
                                    r_BReqComplete <= 'b1;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                                else if (A[1:0] == 2'b10) begin
                                    r_SIZ <= SIZ_1;
                                    r_ATmp <= r_ATmp + 2;
                                    r_BusState <= BS_WRITE_S0;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                                else begin
                                    r_SIZ <= SIZ_2;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_WRITE_S0;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                            end
                            else if (nDSACK == DSACK_16Bit) begin
                                if (A[0] == 0) begin
                                    r_SIZ <= SIZ_1;
                                    r_ATmp <= r_ATmp + 2;
                                    r_BusState <= BS_WRITE_S0;
                                    r_BusAltState <= BS_WRITE_S5;
                                end else begin
                                    r_SIZ <= SIZ_2;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_WRITE_S0;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                            end
                            else begin
                                r_SIZ <= SIZ_2;
                                r_ATmp <= r_ATmp + 1;
                                r_BusState <= BS_WRITE_S0;
                                r_BusAltState <= BS_WRITE_S5;
                            end
                        end
                        SIZ_2: begin
                            if (nDSACK == DSACK_32Bit) begin
                                if (A[1:0] == 2'b00) begin
                                    r_BusState <= BS_IDLE;
                                    r_BReqComplete <= 'b1;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                                else if (A[1:0] == 2'b01) begin
                                    r_BusState <= BS_IDLE;
                                    r_BReqComplete <= 'b1;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                                else if (A[1:0] == 2'b10) begin
                                    r_BusState <= BS_IDLE;
                                    r_BReqComplete <= 'b1;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                                else begin
                                    r_SIZ <= SIZ_1;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_WRITE_S0;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                            end
                            else if (nDSACK == DSACK_16Bit) begin
                                if (A[0] == 0) begin
                                    r_BusState <= BS_IDLE;
                                    r_BReqComplete <= 'b1;
                                    r_BusAltState <= BS_WRITE_S5;
                                end else begin
                                    r_SIZ <= SIZ_1;
                                    r_ATmp <= r_ATmp + 1;
                                    r_BusState <= BS_WRITE_S0;
                                    r_BusAltState <= BS_WRITE_S5;
                                end
                            end
                            else begin
                                r_SIZ <= SIZ_1;
                                r_ATmp <= r_ATmp + 1;
                                r_BusState <= BS_WRITE_S0;
                                r_BusAltState <= BS_WRITE_S5;
                            end
                        end
                        SIZ_1: begin
                            r_BusState <= BS_IDLE;
                            r_BReqComplete <= 'b1;
                            r_BusAltState <= BS_WRITE_S5;
                        end
                    endcase
                end
            end

            endcase
        end

    end

    always @(negedge CLK) begin
        case (r_BusAltState)
            BS_RESET: begin
                r_AS <= 'b1;
                r_DS <= 'b1;
                r_Latched <= 'b0;
            end

            BS_IDLE: begin
                r_AS <= 'b1;
                r_DS <= 'b1;
            end

            BS_READ_S1: begin
                r_AS <= 'b0;
                r_DS <= 'b0;
                r_Latched <= 'b0;
            end

            BS_READ_S3: begin
                r_AltDBEN <= 'b0;
                if (nDSACK != DSACK_Wait) begin
                    r_Latched <= 'b1;
                    r_LatchData[31:0] <= D[31:0];
                end
            end

            BS_READ_S5: begin
                r_AS <= 'b1;
                r_DS <= 'b1;
                r_AltDBEN <= 'b1;
                r_Latched <= 'b0;
                if (r_BusState == BS_IDLE)
                    r_A <= {32{1'bZ}};
            end

            BS_WRITE_S1: begin
                r_AS <= 'b0;
                r_AltDBEN <= 'b0;
                r_Latched <= 'b0;
            end

            BS_WRITE_S3: begin
                r_DS <= 'b0;
                r_AltDBEN <= 'b1;
                if (nDSACK != DSACK_Wait) begin
                    r_Latched <= 'b1;
                end
            end

            BS_WRITE_S5: begin
                r_DS <= 'b1;
                r_AS <= 'b1;
                r_AltDBEN <= 'b1;
                r_Latched <= 'b0;
                if (r_BusState == BS_IDLE) begin
                    r_A <= {32{1'bZ}};
                    r_D <= {32{1'bZ}};
                end
            end

        endcase
    end

endmodule
