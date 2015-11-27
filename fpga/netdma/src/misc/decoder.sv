/*
  Legal Notice: Copyright 2015 STC Metrotek. 

  This file is part of the Netdma ip core.

  Netdma ip core is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Netdma ip core is distributed in the hope that it will be useful, but 
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Netdma ip core. If not, see <http://www.gnu.org/licenses/>.
*/
/*
  Author: Dmitry Hodyrev d.hodyrev@metrotek.spb.ru 
  Date: 22.10.2015
*/
/*
   A simple decoder 
*/

module decoder #( 
  parameter                     RANGE = 4 
  )
  (  
  input  [RANGE-1:0]            in,

  output [2**RANGE-1:0]         out
);

  logic [RANGE-1:0] a;
  logic [2**RANGE-1:0] b;

  always_comb 
    begin
      b     = '0;
      b[a] = 1'b1;
    end

  assign a = in;
  assign out = b;

endmodule

