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

    input [2:0]     BR

);
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
        xxxx - lowest 4 bits are "don't care"

        set 0..3 selected based on PLRU-m (DOI: 10.1145/986537.986601)
    */
    integer i;
    reg [148:0] cache [0:3][0:255];
    reg [3:0] plru[0:255];

    reg [63:0] cache_miss_cnt;
    reg [63:0] cache_hit_cnt;

    reg [3:0] state;
    
    wire [148:0] way_0 = cache[0][Ain[11:4]];
    wire [148:0] way_1 = cache[1][Ain[11:4]];
    wire [148:0] way_2 = cache[2][Ain[11:4]];
    wire [148:0] way_3 = cache[3][Ain[11:4]];

    wire match_0 = way_0[148:129] == Ain[31:12] ? 'b1 : 'b0;
    wire match_1 = way_1[148:129] == Ain[31:12] ? 'b1 : 'b0;
    wire match_2 = way_2[148:129] == Ain[31:12] ? 'b1 : 'b0;
    wire match_3 = way_3[148:129] == Ain[31:12] ? 'b1 : 'b0;

    wire valid_0 = way_0[128];
    wire valid_1 = way_1[128];
    wire valid_2 = way_2[128];
    wire valid_3 = way_3[128];

    wire valid = valid_0 | valid_1 | valid_2 | valid_3;
    wire match = match_0 | match_1 | match_2 | match_3;

    wire [3:0] plru_sel = plru[Ain[11:4]];
    wire [2:0] plru_sum = plru_sel[0] + plru_sel[1] + plru_sel[2] + plru_sel[3];

    localparam ST_IDLE = 'b0;

    localparam BR_NONE = 'd0;
    localparam BR_READ = 'd1;
    localparam BR_WRITE = 'd2;

    always @(posedge CLK) begin
        if (nRESET == 'b0) begin
            for (i = 0; i < 256; i++) begin
                plru[i] <= 'b0000;
                cache[0][i] <= 'b0;
                cache[1][i] <= 'b0;
                cache[2][i] <= 'b0;
                cache[3][i] <= 'b0;
                cache_miss_cnt <= 'b0;
                cache_hit_cnt <= 'b0;
                state <= ST_IDLE;
            end
        end
        else begin
            case (state)
                ST_IDLE: begin
                    if (BR == BR_READ) begin
                        if (valid && match) begin
                            cache_hit_cnt <= cache_hit_cnt + 'b1;

                            if (plru_sum >= 'b11) plru[Ain[11:4]] <= 'b0;
                        end
                        else begin
                            cache_miss_cnt <= cache_miss_cnt + 'b1;
                        end
                    end
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
        xxxx - lowest 4 bits are "don't care"

        set 0..3 selected based on PLRU-m (DOI: 10.1145/986537.986601)
    */
    reg [152:0] cache [0:3][0:255];
    reg [3:0] plru[0:255];

    always @(posedge CLK) begin
        
    end

endmodule
