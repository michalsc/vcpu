/*
    Copyright © 2021 Michal Schulz <michal.schulz@gmx.de>
    https://github.com/michalsc

    This Source Code Form is subject to the terms of the
    Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed
    with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

module INSNCache (
    input           nRESET,
    input           CLK,
    input [31:0]    Ain,
    input [31:0]    Din,
    output [31:0]   Aout,
    output [15:0]   Out,

    input [2:0]     BRin,
    output [2:0]    BRout,
    output [1:0]    SIZout,
    output          BRcompl_out,
    input           BRcompl_in

);
    `include "vcpu.vh"
	
    /* 
        16KB instruction cache - 4-way set of 256 entries, 20 bit tag
        Cache line layout :
            [    TAG    ][V][   L0   ][   L1   ][   L2   ][   L3   ]
        
        TAG - 20 topmost bits of address
        V - valid flag
        L0..L3 - four longwords from the address

        Address:
            [    TAG    ][ WAY ][xxxx]

        TAG - same as above
        WAY - selects one of 256 ways
        xxxx - lowest 4 bits are the position within cache line

        set 0..3 selected based on PLRU-m (DOI: 10.1145/986537.986601)
    */
	 
	localparam ST_IDLE = 0;
    localparam ST_SEARCHING = 1;
    localparam ST_FETCH_0 = 2;
    localparam ST_FETCH_1 = 3;
    localparam ST_FETCH_2 = 4;
    localparam ST_FETCH_3 = 5;
    localparam ST_FETCH_COMPLETE = 6;
	localparam ST_RESET = 7;
	
	wire [3:0] plru_data;
	reg [3:0] plru_wrdata;
	reg plru_wren;
	
	wire [148:0] cache_w0_data;
	wire [148:0] cache_w1_data;
	wire [148:0] cache_w2_data;
	wire [148:0] cache_w3_data;
	reg [148:0] cache_wrdata;
	reg cache_w0_wren;
	reg cache_w1_wren;
	reg cache_w2_wren;
	reg cache_w3_wren;
	
	reg [31:0] Areq;
    reg [31:0] A;
    reg [15:0] Data;
    reg completed;
    reg fetched;
	
    assign BRcompl_out = completed;
    assign Out = Data;
    assign Aout = A;

    localparam CL_TagHi = 148;
    localparam CL_TagLo = 129;
    localparam CL_V = 128;
    localparam CL_L0Hi = 127;
    localparam CL_L0Lo = 96;
    localparam CL_L1Hi = 95;
    localparam CL_L1Lo = 64;
    localparam CL_L2Hi = 63;
    localparam CL_L2Lo = 32;
    localparam CL_L3Hi = 31;
    localparam CL_L3Lo = 0;
	
	reg [2:0] br;
    reg [1:0] siz;
	
	assign BRout = br;
	assign SIZout = siz;
	
	reg [2:0] state;
	reg [63:0] cache_miss_cnt;
    reg [63:0] cache_hit_cnt;

	RAM4 plru(
		.address(cache_addr),
		.clock(CLK),
		.wren(plru_wren),
		.data(plru_wrdata),
		.q(plru_data)
	);
	
	RAM149 cache_w0(
		.address(cache_addr),
		.clock(CLK),
		.wren(cache_w0_wren),
		.data(cache_wrdata),
		.q(cache_w0_data)
	);
	
	RAM149 cache_w1(
		.address(cache_addr),
		.clock(CLK),
		.wren(cache_w1_wren),
		.data(cache_wrdata),
		.q(cache_w1_data)
	);
	
	RAM149 cache_w2(
		.address(cache_addr),
		.clock(CLK),
		.wren(cache_w2_wren),
		.data(cache_wrdata),
		.q(cache_w2_data)
	);
	
	RAM149 cache_w3(
		.address(cache_addr),
		.clock(CLK),
		.wren(cache_w3_wren),
		.data(cache_wrdata),
		.q(cache_w3_data)
	);
	
	wire [3:0] pos = Areq[3:0];
    wire [7:0] set = Areq[11:4];
	wire [7:0] set_in = Ain[11:4];
    wire [19:0] tag = Areq[31:12];
	wire [7:0] cache_addr= set;
	
	reg [3:0] way_sel;
    wire [148:0] way_0 = cache_w0_data;
    wire [148:0] way_1 = cache_w1_data;
    wire [148:0] way_2 = cache_w2_data;
    wire [148:0] way_3 = cache_w3_data;

    wire match_0 = way_0[CL_TagHi:CL_TagLo] == tag ? 'b1 : 'b0;
    wire match_1 = way_1[CL_TagHi:CL_TagLo] == tag ? 'b1 : 'b0;
    wire match_2 = way_2[CL_TagHi:CL_TagLo] == tag ? 'b1 : 'b0;
    wire match_3 = way_3[CL_TagHi:CL_TagLo] == tag ? 'b1 : 'b0;

    wire valid_0 = way_0[CL_V];
    wire valid_1 = way_1[CL_V];
    wire valid_2 = way_2[CL_V];
    wire valid_3 = way_3[CL_V];

    wire valid = valid_0 | valid_1 | valid_2 | valid_3;
    wire match = match_0 | match_1 | match_2 | match_3;

    wire [3:0] plru_sel = plru_data;
    wire [2:0] plru_sum = { 2'b0, plru_sel[0]} + 
                          { 2'b0, plru_sel[1]} + 
                          { 2'b0, plru_sel[2]} + 
                          { 2'b0, plru_sel[3]};

	always @(posedge CLK) begin
        if (nRESET == 'b0) begin
            state <= ST_RESET;
			Areq[12:4] <= 'b0; //cache_addr <= 'b0;
			br <= 3'bZZZ;
			siz <= 2'bZZ;
        end
		case(state)
			ST_RESET: begin
				br <= 3'bZZZ;
				siz <= 2'bZZ;
				A[31:0] <= 32'hZZZZZZZZ;
				
				if (Areq[12] == 'b0) begin
					Areq[12:4] <= Areq[12:4] + 'b1;
				end else begin
					state <= ST_IDLE;
				end
			end
			
			ST_IDLE: begin
				br <= 3'bZZZ;
				siz <= 2'bZZ;
				A[31:0] <= 32'hZZZZZZZZ;

				if (BRin == BR_READ) begin
					Areq <= Ain;
					state <= ST_SEARCHING;
				end
			end

			ST_SEARCHING: begin
				if (completed) begin
					state <= ST_IDLE;
				end
				else begin
					state <= ST_FETCH_0;
					A[31:0] <= { Areq[31:4], 4'b0000 };
					br <= BR_READ;
					siz <= 0;
				end
			end

			ST_FETCH_0: begin
				if (fetched == 'b1) begin
					state <= ST_FETCH_1;
					A[31:0] <= { Areq[31:4], 4'b0100 };
					br <= BR_READ;
				end else br <= 0;
			end

			ST_FETCH_1: begin
				if (fetched == 'b1) begin
					state <= ST_FETCH_2;
					A[31:0] <= { Areq[31:4], 4'b1000 };
					br <= BR_READ;
				end else br <= 0;
			end

			ST_FETCH_2: begin
				if (fetched == 'b1) begin
					state <= ST_FETCH_3;
					A[31:0] <= { Areq[31:4], 4'b1100 };
					br <= BR_READ;
				end else br <= 0;
			end

			ST_FETCH_3: begin
				if (fetched == 'b1) begin
					br <= 3'bZZZ;
					siz <= 2'bZZ;
					A[31:0] <= 32'hZZZZZZZZ;
					state <= ST_FETCH_COMPLETE;
				end else br <= 0;
			end

			ST_FETCH_COMPLETE:
				state <= ST_IDLE;
		endcase
	end
	
	always @(negedge CLK) begin
		if (nRESET == 'b0) begin
			cache_miss_cnt <= 'b0;
			cache_hit_cnt <= 'b0;
			completed <= 'b0;
			cache_wrdata <= 'b0;
			cache_w0_wren <= 'b1;
			cache_w1_wren <= 'b1;
			cache_w2_wren <= 'b1;
			cache_w3_wren <= 'b1;
			plru_wren <= 'b1;
			plru_wrdata <= 'b0;
		end
		case (state)
			
			ST_IDLE: begin
				completed <= 'b0;
				cache_w0_wren <= 'b0;
				cache_w1_wren <= 'b0;
				cache_w2_wren <= 'b0;
				cache_w3_wren <= 'b0;
				plru_wren <= 'b0;
			end
			
			ST_FETCH_COMPLETE,
			ST_SEARCHING: begin
				if (BRin == BR_READ) begin
				
					if (valid && match) begin
					
						if (state == ST_SEARCHING)
							cache_hit_cnt <= cache_hit_cnt + 'b1;
                        
						completed <= 'b1;
						plru_wren <= 'b1;
						
						if (valid_0 && match_0) begin
							case (pos)
								0: Data <= way_0[127:112];
                                2: Data <= way_0[111:96];
                                4: Data <= way_0[95:80];
								6: Data <= way_0[79:64];
                                8: Data <= way_0[63:48];
                                10: Data <= way_0[47:32];
								12: Data <= way_0[31:16];
								14: Data <= way_0[15:0];
							endcase
							if (state == ST_SEARCHING) begin
								if (plru_sum >= 'b11) 
									plru_wrdata <= 4'b0001;
								else 
									plru_wrdata <= { plru_data[3:1], 1'b1 };
							end
						end
					    else if (valid_1 && match_1) begin
							case (pos)
								0: Data <= way_1[127:112];
                                2: Data <= way_1[111:96];
                                4: Data <= way_1[95:80];
								6: Data <= way_1[79:64];
                                8: Data <= way_1[63:48];
                                10: Data <= way_1[47:32];
								12: Data <= way_1[31:16];
								14: Data <= way_1[15:0];
							endcase
							if (state == ST_SEARCHING) begin
								if (plru_sum >= 'b11) 
									plru_wrdata <= 4'b0010;
								else 
									plru_wrdata <= { plru_data[3:2], 1'b1, plru_data[0] };
							end
						end
						else if (valid_2 && match_2) begin
							case (pos)
								0: Data <= way_2[127:112];
                                2: Data <= way_2[111:96];
                                4: Data <= way_2[95:80];
								6: Data <= way_2[79:64];
                                8: Data <= way_2[63:48];
                                10: Data <= way_2[47:32];
								12: Data <= way_2[31:16];
								14: Data <= way_2[15:0];
							endcase
							if (state == ST_SEARCHING) begin
								if (plru_sum >= 'b11) 
									plru_wrdata <= 4'b0100;
								else 
									plru_wrdata <= { plru_data[3], 1'b1, plru_data[1:0] };
							end
						end	
						else if (valid_3 && match_3) begin
							case (pos)
								0: Data <= way_3[127:112];
                                2: Data <= way_3[111:96];
                                4: Data <= way_3[95:80];
								6: Data <= way_3[79:64];
                                8: Data <= way_3[63:48];
                                10: Data <= way_3[47:32];
								12: Data <= way_3[31:16];
								14: Data <= way_3[15:0];
							endcase
							if (state == ST_SEARCHING) begin
								if (plru_sum >= 'b11) 
									plru_wrdata <= 4'b1000;
								else 
									plru_wrdata <= { 1'b1, plru_data[2:0] };
							end
						end
					end
					else begin
						cache_miss_cnt <= cache_miss_cnt + 'b1;
						completed <= 'b0;

						if (plru_sel[0] == 0) begin
							way_sel <= 4'b0001;
							if (plru_sum >= 'b11) 
								plru_wrdata <= 4'b0001;
							else 
								plru_wrdata <= { plru_data[3:1], 1'b1 };
						end else if (plru_sel[1] == 0) begin
							way_sel <= 4'b0010;
							if (plru_sum >= 'b11) 
								plru_wrdata <= 4'b0010;
							else 
								plru_wrdata <= { plru_data[3:2], 1'b1, plru_data[0] };
						end else if (plru_sel[2] == 0) begin
							way_sel <= 4'b0100;
							if (plru_sum >= 'b11) 
								plru_wrdata <= 4'b0100;
							else 
								plru_wrdata <= { plru_data[3], 1'b1, plru_data[1:0] };
						end else begin
							way_sel <= 4'b1000;
							if (plru_sum >= 'b11) 
								plru_wrdata <= 4'b1000;
							else 
								plru_wrdata <= { 1'b1, plru_data[2:0] };
						end
					end
				end
			end
			
			ST_FETCH_0: begin
				if (BRcompl_in == 'b1) begin
					fetched <= 'b1;	
					cache_wrdata[CL_L0Hi:CL_L0Lo] <= Din;
				end 
				else fetched <= 'b0;
			end

			ST_FETCH_1: begin
				if (BRcompl_in == 'b1) begin
					fetched <= 'b1;
					cache_wrdata[CL_L1Hi:CL_L1Lo] <= Din;
				end 
				else fetched <= 'b0;
			end

			ST_FETCH_2: begin
				if (BRcompl_in == 'b1) begin
					fetched <= 'b1;
					cache_wrdata[CL_L2Hi:CL_L2Lo] <= Din;
				end 
				else fetched <= 'b0;
			end
			
			ST_FETCH_3: begin
				if (BRcompl_in == 'b1) begin
					fetched <= 'b1;
					cache_wrdata[CL_L3Hi:CL_L3Lo] <= Din;
					cache_wrdata[CL_V] <= 'b1;
                    cache_wrdata[CL_TagHi:CL_TagLo] <= tag;
					cache_w0_wren <= way_sel[0];
					cache_w1_wren <= way_sel[1];
					cache_w2_wren <= way_sel[2];
					cache_w3_wren <= way_sel[3];
				end
				else fetched <= 'b0;
			end

		endcase

	end

endmodule

module DATACache (
    input CLK
);
    /* 
        16KB data cache - 4-way set of 256 entries, 20 bit tag
        Cache line layout :
            [    TAG    ][V][D0][D1][D2][D3][   L0   ][   L1   ][   L2   ][   L3   ]
        
        TAG - 20 topmost bits of address
        V - valid flag
        L0..L3 - four longwords from the address
        D0..D3 - four dirty markers for corresponding longwords

        Address:
            [    TAG    ][ WAY ][xxxx]

        TAG - same as above
        WAY - selects one of 256 ways
        xxxx - lowest 4 bits are the position within cache line

        set 0..3 selected based on PLRU-m (DOI: 10.1145/986537.986601)
    */


endmodule
