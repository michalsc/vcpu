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
    /* 16KB instruction cache - 4-way set of 256 entries, 20 bit tag */
    reg [148:0] cache [1:0][7:0];

    always @(posedge CLK) begin
        
    end

endmodule

module DATACache (
    input CLK
);
    /* 16KB data cache - 4-way set of 256 entries, 20 bit tag */
    reg [152:0] cache [1:0][7:0];

    always @(posedge CLK) begin
        
    end

endmodule
