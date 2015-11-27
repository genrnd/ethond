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

import eth_pkt_lib::*;

module tx_cpu
#(
  parameter eth_pkt_if_t IF_PROPERTIES = eth_pkt_lib::DEFAULT_PROPERTIES
)
(
  input                        clk_i,
  input                        rst_i,

  // CPU side
  eth_pkt_if.i                 pkt_i,  
  
  // Network side
  eth_pkt_if.o                 pkt_o
);

eth_pkt_if #( 
  .IF_PROPERTIES ( IF_PROPERTIES ) 
) wr_pkt ( clk_i );

eth_pkt_if #(
  .IF_PROPERTIES ( IF_PROPERTIES ) 
) rd_pkt ( clk_i );

logic stat_fifo_wr_ready;
logic stat_fifo_rd_ready;

eth_pkt_if_control_changer #(
  .IF_PROPERTIES                          ( IF_PROPERTIES      ),
  .READY_ACTION                           ( "AND"              ),
  .VAL_ACTION                             ( "AND"              )
) wr_pkt_maker (
  .third_party_ready_i                    ( stat_fifo_wr_ready ),
  .third_party_val_i                      ( stat_fifo_wr_ready ),

  .pkt_i                                  ( pkt_i              ),

  .pkt_o                                  ( wr_pkt             )

);

eth_pkt_fifo #(
  .IF_PROPERTIES                          ( IF_PROPERTIES                     ),
  .DUAL_CLOCK                             ( 0                                 ),
  .SHOWAHEAD                              ( "ON"                              ),
  .USE_WR_ALMOST_FULL_LIKE_WR_PKT_READY   ( 1                                 )
) pkt_fifo (
  .rst_i                                  ( rst_i                             ),

  .wr_pkt_i                               ( wr_pkt                            ),
  .rd_pkt_o                               ( rd_pkt                            )
    
);

eth_pkt_if_control_changer #(
  .IF_PROPERTIES                          ( IF_PROPERTIES      ),
  .READY_ACTION                           ( "AND"              ),
  .VAL_ACTION                             ( "AND"              )
) out_pkt_maker (
  .third_party_ready_i                    ( stat_fifo_rd_ready ),
  .third_party_val_i                      ( stat_fifo_rd_ready ),

  .pkt_i                                  ( rd_pkt             ),

  .pkt_o                                  ( pkt_o              )

);

// используем эту фифошку как просто флаг того, 
// что весь пакет от проца накопился 

logic stat_fifo_empty_w;
logic stat_fifo_almost_full_w;

logic stat_fifo_wr_req;
logic stat_fifo_rd_req;


assign stat_fifo_wr_ready = !stat_fifo_almost_full_w;
assign stat_fifo_rd_ready = !stat_fifo_empty_w;

assign stat_fifo_wr_req = pkt_i.ready && pkt_i.val && pkt_i.eop;
assign stat_fifo_rd_req = pkt_o.ready && pkt_o.val && pkt_o.eop;

stat_fifo_generic #( 
   .AWIDTH                                ( 8                                 ),
   .DWIDTH                                ( 1                                 ),
   .DUAL_CLOCK                            ( 0                                 ),
   .SHOWAHEAD                             ( "ON"                              ),
   .SAFE_WORDS                            ( 10                                )
) stat_fifo(
  .rst_i                                  ( rst_i                             ),
    
  .wr_clk_i                               ( clk_i                             ),
  .wr_req_i                               ( stat_fifo_wr_req                  ),
  .wr_data_i                              ( 1'b1                              ),

  .rd_clk_i                               ( clk_i                             ),
  .rd_req_i                               ( stat_fifo_rd_req                  ),
  .rd_data_o                              (                                   ),
    
  .rd_empty_o                             ( stat_fifo_empty_w                 ),
  .wr_almost_full_o                       ( stat_fifo_almost_full_w           )
);

endmodule
