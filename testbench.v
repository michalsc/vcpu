`include "./alu.v"
`timescale 1ns/1ps

module testbench;

    `include "vcpu.vh"

    reg clk = 0;
    reg [3:0] sel = 0; 
    reg [31:0] A = 0;
    reg [31:0] B = 0;
    wire [31:0] X;
    wire busy;
    reg reset = 0;
    integer i;

    reg r_X = 0;
    wire [4:0] XNZVC;

    ALU #(.N(32)) ALU_32(
        .in_A(A[31:0]),
        .in_B(B[31:0]),
        .in_OP(sel),
        .in_X(r_X),
        .out_XNZVC(XNZVC),
        .out_RES(X[31:0])
    );
    
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);

        sel <= op_ADDX;
        A <= 0;
        B <= 0;

        @(posedge clk)
        reset <= 1; #1 reset <= 0;

        for (i=0; i<5; i = i + 1) begin #1; end;
        @(posedge clk)
        
        r_X <= XNZVC[bitpos_X];
        A <= 1;
        B <= 0;

        reset <= 1; #1 reset <= 0;

        for (i=0; i<5; i = i + 1) begin #1; end;
        @(posedge clk)

        r_X <= XNZVC[bitpos_X]; #1;
        A <= 32'h7fffffff;
        B <= 32'h00000010;

        reset <= 1; #1 reset <= 0;

        for (i=0; i<5; i = i + 1) begin #1; end;
        @(posedge clk)

        r_X <= XNZVC[bitpos_X]; #1;
        A <= 32'hf0000000;
        B <= 32'h80000000;

        reset <= 1; #1 reset <= 0;

        for (i=0; i<5; i = i + 1) begin #1; end;
        @(posedge clk)

        r_X <= XNZVC[bitpos_X]; #1;
        A <= 0;
        B <= 0;

        reset <= 1; #1 reset <= 0;

        for (i=0; i<5; i = i + 1) begin #1; end;
        @(posedge clk)

        r_X <= XNZVC[bitpos_X]; #1;
        A <= 0;
        B <= 1;

        reset <= 1; #1 reset <= 0;
        
        for (i=0; i<5; i = i + 1) begin #1; end;
        @(posedge clk)

        r_X <= XNZVC[bitpos_X]; #1;
        A <= 32'h7fffffff;
        B <= 32'h00000010;

        reset <= 1; #1 reset <= 0;

        for (i=0; i<5; i = i + 1) begin #1; end;
        @(posedge clk)

        r_X <= XNZVC[bitpos_X]; #1;
        A <= 32'hf0000000;
        B <= 32'h80000000;

        reset <= 1; #1 reset <= 0;

        for (i=0; i<5; i = i + 1) begin #1; end;
        @(posedge clk)

        $finish;
    end

    always #1 clk <= ~clk;

endmodule
