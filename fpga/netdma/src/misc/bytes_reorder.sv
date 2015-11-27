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
  This is a simple module that implements simple LSB -> MSB 
  byte reordering. It doesn't conain any combinational logic, 
  just wire routing. Product example:
 
  [[3][2][1][0]] // data_unit
  --------------
  [[0][1][2][3]] // reordered data unit 

    1.0 -- Initial release

*/


module bytes_reorder #(

  parameter                           NUM_BYTES = 8
 )
 (
  input [NUM_BYTES-1:0][7:0]          data_unit,

  output [NUM_BYTES-1:0][7:0]         reordered_data_unit
);

  localparam NUMWIDTH = $clog2(NUM_BYTES);

  generate
    genvar i;
      for( i = 0; i < NUM_BYTES; i++ )
        begin : data_mapping
          assign reordered_data_unit[i] = data_unit[~i & {NUMWIDTH{1'b1}}];
        end : data_mapping
  endgenerate
endmodule

 
