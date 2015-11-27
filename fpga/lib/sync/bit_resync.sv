/*
  Legal Notice: Copyright 2015 STC Metrotek.

  This file is part of the EthOnd BSP.

  EthOnd BSP is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  EthOnd BSP is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with EthOnd BSP. If not, see <http://www.gnu.org/licenses/>.
*/

module bit_resync #( 
  parameter SYNC_DEPTH = 3 
)
(
  input  clk_i,
  input  rst_i,

  input  d_i,
  output d_o

);

altera_std_synchronizer #( 
  .depth              ( SYNC_DEPTH ) 
) alt_sync (
  .clk                (  clk_i     ), 
  .reset_n            ( ~rst_i     ), 
  .din                (  d_i       ), 
  .dout               (  d_o       ) 
);

endmodule
