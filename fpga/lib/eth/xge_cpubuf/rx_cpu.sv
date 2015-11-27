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



module rx_cpu(
  input                        rst_i,

  // Network side
  eth_pkt_if.i                 pkt_i,  

  input        [15:0]          pkt_size_i,
  input        [15:0]          cpu_mtu_i,
  output logic                 pkt_wa_o,
  
  // CPU side
  eth_pkt_if.o                 pkt_o
);



logic [13:0] fifo_empty_bytes_w;
logic        fifo_empty;
logic        fifo_almost_full;

eth_pkt_fifo #(
  .DUAL_CLOCK                             ( 0                      ),
  .SHOWAHEAD                              ( "ON"                   )
) pkt_fifo (
   
  .rst_i                                  ( rst_i                  ),

  .wr_pkt_i                               ( pkt_i                  ),
  .rd_pkt_o                               ( pkt_o                  ),
    
  .rd_empty_o                             ( fifo_empty             ),
  .wr_almost_full_o                       ( fifo_almost_full       ),
  .usedw_o                                (                        ),
  .empty_bytes_o                          ( fifo_empty_bytes_w     )
);



// Write (network) side 
always_comb
  if( fifo_almost_full )
    pkt_wa_o = 1'b0;
  else
    if( ( fifo_empty_bytes_w > pkt_size_i ) && ( pkt_size_i <= cpu_mtu_i ) )
      pkt_wa_o = 1'b1;
    else
      pkt_wa_o = 1'b0;


endmodule
