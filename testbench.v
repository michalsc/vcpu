`include "./alu.v"
`timescale 1ns/1ps

module testbench;

    reg clk = 0;
    reg [31:0] A;
    reg [31:0] B;
    wire [31:0] X;

    wire [4:0] XNZVC;

    alu m_alu(
        .in_a(A),
        .in_b(B),
        .alu_size(2'b10),
        .alu_sel(4'b0000),
        .out_result(X),
        .out_xnzvc(XNZVC)
    );

    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);

        A <= 0;
        B <= 0;

        repeat(5) @(posedge clk)

        A <= 1;
        B <= 0;
        
        repeat(5) @(posedge clk)

        A <= 32'h7fffffff;
        B <= 32'h00000010;

        repeat(5) @(posedge clk)

        A <= 32'hf0000000;
        B <= 32'h80000000;

        repeat(5) @(posedge clk)

        $finish;
    end

    always #1 clk <= ~clk;

endmodule
