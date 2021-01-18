/*
    Copyright © 2021 Michal Schulz <michal.schulz@gmx.de>
    https://github.com/michalsc

    This Source Code Form is subject to the terms of the
    Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed
    with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

module INSNCache (
    input   CLK
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

    reg [148:0] cache [0:3][0:255];
    reg [3:0] plru[0:255];

    always @(posedge CLK) begin
        
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
