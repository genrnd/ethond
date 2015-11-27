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
   A simple positive edge detector
*/

module posedge_detector (

  input                          clk_i,

  input                          rst_i,
  
  input                          signal_i,
  
  output                         edge_o
);

  logic r;
  always_ff @(posedge clk_i, posedge rst_i)
    if( rst_i ) 
      r <= 0;
    else        
      r <= signal_i;

  assign edge_o = ~r & signal_i;
endmodule
