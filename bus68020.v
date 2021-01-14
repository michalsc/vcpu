`timescale 1ns/1ps

module BUS_68020(
    output [2:0]    FC,     // Function codes, three-state
    output [31:0]   A,      // Address bus, three-state
    inout [31:0]    D,      // Data bus, three-state
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

    inout           nRESET, // System reset
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
    wire out_RESET;

    assign nRESET = (out_RESET == 1) ? 1'bZ: 1'b0;
    assign in_RESET = (out_RESET == 1) ? nRESET : 1'b1; 

endmodule
