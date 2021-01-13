`timescale 1ns/1ps

module VCPU(
    input       in_CLK,
    input       in_RESET,

    output      out_RESET
);
    `include "vcpu.vh"

    reg RESET;
    reg [9:0] RESETcnt;

    reg [31:0] D0;
    reg [31:0] D1;
    reg [31:0] D2;
    reg [31:0] D3;
    reg [31:0] D4;
    reg [31:0] D5;
    reg [31:0] D6;
    reg [31:0] D7;

    reg [31:0] A0;
    reg [31:0] A1;
    reg [31:0] A2;
    reg [31:0] A3;
    reg [31:0] A4;
    reg [31:0] A5;
    reg [31:0] A6;

    reg [31:0] ISP;
    reg [31:0] MSP;
    reg [31:0] USP;

    reg [31:0] PC;

    reg [63:0] CYCLE_CNT;

    always @(posedge in_CLK) begin
        if (in_RESET == 0) begin
            
            
            PC <= 'b0;
            CYCLE_CNT <= 'b0;

        end else begin
            CYCLE_CNT <= CYCLE_CNT + 'b1;
        end;
    end

endmodule
