`include "./alu.v"
`include "./vcpu.v"
`timescale 1ns/1ps

module testbench;

    `include "vcpu.vh"

    reg reset = 1;
    reg clk = 1;
    reg [3:0] sel = 0; 
    reg [31:0] A = 0;
    reg [31:0] B = 0;
    wire [31:0] X;
    wire [4:0] chg_XNZVC;

    reg r_X = 0;
    wire [4:0] XNZVC;

    VCPU CPU(
        .in_RESET(reset),
        .in_CLK(clk)
    );

    ALU #(.N(32)) ALU_32(
        .in_CLK(clk),
        .in_A(A[31:0]),
        .in_B(B[31:0]),
        .in_OP(sel),
        .in_X(r_X),
        .out_XNZVC(XNZVC),
        .out_XNZVC_chg(chg_XNZVC),
        .out_RES(X[31:0])
    );
    
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);

        #0.3; reset <= 1'b0;
        #7.14; reset <= 1'b1;

        sel = op_ROXx;
        A = 0;
        B = 0;

        #10;
        
        r_X = XNZVC[bitpos_X];
        A = 'h8ff;
        B = 'h84;

        #10;
        
        r_X = XNZVC[bitpos_X];
        B = 32'h00000010;

        #10;

        r_X = XNZVC[bitpos_X];
        B = 32'h00000001;

        #10;

        r_X = XNZVC[bitpos_X];
        B = 3;

        #10;

        r_X = XNZVC[bitpos_X];
        B = 5;
        
        #10;

        r_X = XNZVC[bitpos_X]; #1;
        B = 19;

        #10;

        r_X = XNZVC[bitpos_X]; #1;
        B = 8;

        #10;

        #500 $finish;
    end

    always #1 clk = ~clk;

endmodule
