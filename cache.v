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
    integer i;
    reg [148:0] cache [0:3][0:255];
    reg [3:0] plru[0:255];
    reg [2:0] cnt;
    reg [31:0] Areq;
    reg [31:0] A;
    reg [15:0] Data;
    reg completed;
    reg [2:0] br;
    reg [1:0] siz;

    assign BRcompl_out = completed;
    assign BRout = br;
    assign Out = Data;
    assign Aout = A;
    assign SIZout = siz;

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

    reg [63:0] cache_miss_cnt;
    reg [63:0] cache_hit_cnt;

    reg [3:0] state;

    wire [3:0] pos = Areq[3:0];
    wire [7:0] set = Areq[11:4];
    wire [19:0] tag = Areq[31:12];
    
    reg [1:0] way_sel;
    wire [148:0] way_0 = cache[0][set];
    wire [148:0] way_1 = cache[1][set];
    wire [148:0] way_2 = cache[2][set];
    wire [148:0] way_3 = cache[3][set];

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

    wire [3:0] plru_sel = plru[set];
    wire [2:0] plru_sum = { 2'b0, plru_sel[0]} + 
                          { 2'b0, plru_sel[1]} + 
                          { 2'b0, plru_sel[2]} + 
                          { 2'b0, plru_sel[3]};

    localparam ST_IDLE = 0;
    localparam ST_SEARCHING = 1;
    localparam ST_FETCH_0 = 2;
    localparam ST_FETCH_1 = 3;
    localparam ST_FETCH_2 = 4;
    localparam ST_FETCH_3 = 5;
    localparam ST_FETCH_COMPLETE = 6;

    localparam BR_NONE = 'd0;
    localparam BR_READ = 'd1;
    localparam BR_WRITE = 'd2;

    reg fetched;

    always @(posedge CLK) begin
        if (nRESET == 'b0) begin
            for (i = 0; i < 256; i++) begin
                plru[i] <= 'b0000;
            end
            br = 3'bZZZ;
            siz = 2'bZZ;
            state <= ST_IDLE;
            Areq <= 'b0;
        end
        else begin
            case (state)
                ST_IDLE: begin
                    br = 3'bZZZ;
                    siz = 2'bZZ;

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
                        br <= 1;
                        siz <= 0;
                    end
                end

                ST_FETCH_0: begin
                    if (fetched == 'b1) begin
                        state <= ST_FETCH_1;
                        A[31:0] <= { Areq[31:4], 4'b0100 };
                        br <= 1;
                    end else br <= 0;
                end

                ST_FETCH_1: begin
                    if (fetched == 'b1) begin
                        state <= ST_FETCH_2;
                        A[31:0] <= { Areq[31:4], 4'b1000 };
                        br <= 1;
                    end else br <= 0;
                end

                ST_FETCH_2: begin
                    if (fetched == 'b1) begin
                        state <= ST_FETCH_3;
                        A[31:0] <= { Areq[31:4], 4'b1100 };
                        br <= 1;
                    end else br <= 0;
                end

                ST_FETCH_3: begin
                    if (fetched == 'b1) begin
                        br = 3'bZZZ;
                        siz = 2'bZZ;
                        A[31:0] = 32'hZZZZZZZZ;
                        state <= ST_FETCH_COMPLETE;
                    end else br <= 0;
                end

                ST_FETCH_COMPLETE:
                    state <= ST_IDLE;

            endcase
        end
    end

    always @(negedge CLK) begin
        if (nRESET == 'b0) begin
            cache_miss_cnt <= 'b0;
            cache_hit_cnt <= 'b0;
            completed <= 'b0;
            for (i = 0; i < 256; i++) begin
                cache[0][i] <= 'b0;
                cache[1][i] <= 'b0;
                cache[2][i] <= 'b0;
                cache[3][i] <= 'b0;
            end
        end
        else begin
            case (state)
                ST_IDLE: begin
                    completed <= 'b0;
                end

                ST_FETCH_COMPLETE,
                ST_SEARCHING: begin
                    if (BRin == BR_READ) begin
                        if (valid && match) begin
                            if (state == ST_SEARCHING)
                                cache_hit_cnt <= cache_hit_cnt + 'b1;
                            completed <= 'b1;
                            if (valid_0 && match_0) begin
                                    case (pos)
                                    0,
                                    1: Data <=  cache[0][set][127:112];
                                    2,
                                    3: Data <=  cache[0][set][111:96];
                                    4,
                                    5: Data <=  cache[0][set][95:80];
                                    6,
                                    7: Data <=  cache[0][set][79:64];
                                    8,
                                    9: Data <=  cache[0][set][63:48];
                                    10,
                                    11: Data <=  cache[0][set][47:32];
                                    12,
                                    13: Data <=  cache[0][set][31:16];
                                    14,
                                    15: Data <=  cache[0][set][15:0];
                                    endcase
                                if (state == ST_SEARCHING) begin
                                    if (plru_sum >= 'b11) 
                                        plru[set] <= 4'b0001;
                                    else 
                                        plru[set][0] <= 'b1;
                                end
                            end
                            else if (valid_1 && match_1) begin
                                case (pos)
                                    0,
                                    1: Data <=  cache[1][set][127:112];
                                    2,
                                    3: Data <=  cache[1][set][111:96];
                                    4,
                                    5: Data <=  cache[1][set][95:80];
                                    6,
                                    7: Data <=  cache[1][set][79:64];
                                    8,
                                    9: Data <=  cache[1][set][63:48];
                                    10,
                                    11: Data <=  cache[1][set][47:32];
                                    12,
                                    13: Data <=  cache[1][set][31:16];
                                    14,
                                    15: Data <=  cache[1][set][15:0];
                                endcase
                                if (state == ST_SEARCHING) begin
                                    if (plru_sum >= 'b11) 
                                        plru[set] <= 4'b0010;
                                    else 
                                        plru[set][1] <= 'b1;
                                end
                            end
                            else if (valid_2 && match_2) begin
                                case (pos)
                                    0,
                                    1: Data <=  cache[2][set][127:112];
                                    2,
                                    3: Data <=  cache[2][set][111:96];
                                    4,
                                    5: Data <=  cache[2][set][95:80];
                                    6,
                                    7: Data <=  cache[2][set][79:64];
                                    8,
                                    9: Data <=  cache[2][set][63:48];
                                    10,
                                    11: Data <=  cache[2][set][47:32];
                                    12,
                                    13: Data <=  cache[2][set][31:16];
                                    14,
                                    15: Data <=  cache[2][set][15:0];
                                endcase
                                if (state == ST_SEARCHING) begin
                                    if (plru_sum >= 'b11) 
                                        plru[set] <= 4'b0100;
                                    else 
                                        plru[set][2] <= 'b1;
                                end
                            end
                            else if (valid_3 && match_3) begin
                                case (pos)
                                    0,
                                    1: Data <=  cache[3][set][127:112];
                                    2,
                                    3: Data <=  cache[3][set][111:96];
                                    4,
                                    5: Data <=  cache[3][set][95:80];
                                    6,
                                    7: Data <=  cache[3][set][79:64];
                                    8,
                                    9: Data <=  cache[3][set][63:48];
                                    10,
                                    11: Data <=  cache[3][set][47:32];
                                    12,
                                    13: Data <=  cache[3][set][31:16];
                                    14,
                                    15: Data <=  cache[3][set][15:0];
                                endcase
                                if (state == ST_SEARCHING) begin
                                    if (plru_sum >= 'b11) 
                                        plru[set] <= 4'b1000;
                                    else 
                                        plru[set][3] <= 'b1;
                                end
                            end
                        end
                        else begin
                            cache_miss_cnt <= cache_miss_cnt + 'b1;
                            completed <= 'b0;

                            if (plru_sel[0] == 0) begin
                                way_sel <= 0;
                                if (plru_sum >= 'b11) 
                                    plru[set] <= 4'b0001;
                                else 
                                    plru[set][0] <= 'b1;
                            end else if (plru_sel[1] == 0) begin
                                way_sel <= 1;
                                if (plru_sum >= 'b11) 
                                    plru[set] <= 4'b0010;
                                else 
                                    plru[set][1] <= 'b1;
                            end else if (plru_sel[2] == 0) begin
                                way_sel <= 2;
                                if (plru_sum >= 'b11) 
                                    plru[set] <= 4'b0100;
                                else 
                                    plru[set][2] <= 'b1;
                            end else begin
                                way_sel <= 3;
                                if (plru_sum >= 'b11) 
                                    plru[set] <= 4'b1000;
                                else 
                                    plru[set][3] <= 'b1;
                            end
                        end
                    end
                end

                ST_FETCH_0: begin
                    if (BRcompl_in == 'b1) begin
                        fetched <= 'b1;
                        case (way_sel)
                            0: cache[0][set][127:96] <= Din;
                            1: cache[1][set][127:96] <= Din;
                            2: cache[2][set][127:96] <= Din;
                            3: cache[3][set][127:96] <= Din;
                        endcase
                    end else fetched <= 'b0;
                end

                ST_FETCH_1: begin
                    if (BRcompl_in == 'b1) begin
                        fetched <= 'b1;
                        case (way_sel)
                            0: cache[0][set][95:64] <= Din;
                            1: cache[1][set][95:64] <= Din;
                            2: cache[2][set][95:64] <= Din;
                            3: cache[3][set][95:64] <= Din;
                        endcase
                    end else fetched <= 'b0;
                end

                ST_FETCH_2: begin
                    if (BRcompl_in == 'b1) begin
                        fetched <= 'b1;
                        case (way_sel)
                            0: cache[0][set][63:32] <= Din;
                            1: cache[1][set][63:32] <= Din;
                            2: cache[2][set][63:32] <= Din;
                            3: cache[3][set][63:32] <= Din;
                        endcase
                    end else fetched <= 'b0;
                end

                ST_FETCH_3: begin
                    if (BRcompl_in == 'b1) begin
                        fetched <= 'b1;
                        case (way_sel)
                            0: begin 
                                cache[0][set][31:0] <= Din;
                                cache[0][set][CL_V] <= 'b1;
                                cache[0][set][CL_TagHi:CL_TagLo] <= tag; 
                            end
                            1: begin
                                cache[1][set][31:0] <= Din;
                                cache[1][set][CL_V] <= 'b1;
                                cache[1][set][CL_TagHi:CL_TagLo] <= tag; 
                            end
                            2: begin
                                cache[2][set][31:0] <= Din;
                                cache[2][set][CL_V] <= 'b1;
                                cache[2][set][CL_TagHi:CL_TagLo] <= tag; 
                            end
                            3: begin
                                cache[3][set][31:0] <= Din;
                                cache[3][set][CL_V] <= 'b1;
                                cache[3][set][CL_TagHi:CL_TagLo] <= tag; 
                            end
                        endcase
                    end else fetched <= 'b0;
                end
            endcase
        end

    end

endmodule

module DATACache (
    input CLK
);
    /* 
        16KB data cache - 4-way set of 256 entries, 20 bit tag
        Cache line layout :
            [    TAG    ][V][D0][   L0   ][   L1   ][   L2   ][   L3   ][D0][D1][D2][D3]
        
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
    reg [152:0] cache [0:3][0:255];
    reg [3:0] plru[0:255];

    always @(posedge CLK) begin
        
    end

endmodule
