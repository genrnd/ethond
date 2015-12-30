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

`include "../lib/eth/traf_engine/include/defines.vh"

import eth_pkt_lib::*;
import feat_anlz::*;


module mx_traf_engine

(
  input                             clk_i,                 //клок один на всю схему
  input                             rst_i,                 //асинхронный сброс
 

  nic_ctrl_if.app                   nic_if,

  // rx_interface
  rx_engine_if.engine               pkt_rx_i,
  // tx_interface
  eth_pkt_if.o                      pkt_tx_o,

  // network stack
  eth_pkt_if.o                      pkt_to_cpu_o,
  eth_pkt_if.i                      pkt_from_cpu_i


);


parameter eth_pkt_if_t IF_PROPERTIES_RX      = '{ data_width : 64,
                                                  tuser_width : ( $bits( pkt_rx_info_t ) ) };


eth_pkt_if #( .IF_PROPERTIES ( IF_PROPERTIES_RX ) ) pkt_rx                      ( clk_i );
eth_pkt_if #( .IF_PROPERTIES ( IF_PROPERTIES_RX ) ) pkt_rx_d1                   ( clk_i );
eth_pkt_if #( .IF_PROPERTIES ( IF_PROPERTIES_RX ) ) pkt_rx_dmx[RX_DIR_CNT-1:0]  ( clk_i );


pkt_rx_info_t                   pkt_rx_stat_w;
logic                           dir_cpu_wa;
logic                           rx_robot_run_w;
logic [RX_DIR_CNT-1:0]          rx_dir_w;
logic [RX_DIR_CNT-1:0]          rx_dir_d1;   






rx_engine #( 
  .IF_PROPERTIES                          ( IF_PROPERTIES_RX      )
) rx_engine (
  .clk_156m25_i                           ( clk_i                 ), // user int-ce clock
  .reset_156m25_i                         ( rst_i                 ), // reset sync to clk_156m25  
  .pkt_rx_i                               ( pkt_rx_i              ),  
  .nic_if                                 ( nic_if                ),
  // User Rx IF
  .pkt_o                                  ( pkt_rx                )
);




assign pkt_rx_stat_w = pkt_rx.tuser;




rx_dir_resolver  rx_dir_res (
    
  .pkt_rx_stat_i                          ( pkt_rx_stat_w                  ),
  .dir_cpu_wa_i                           ( dir_cpu_wa                     ),   
  .rx_dir_o                               ( rx_dir_w                       )
);


// задерживаем на один такт пока арбитр примет решение
eth_pkt_if_delay #( 
  .IF_PROPERTIES                          ( IF_PROPERTIES_RX       ),
  .DELAY                                  ( 1                      )
) rx_delay (
  .rst_i                                  ( rst_i                  ),
  .pkt_i                                  ( pkt_rx                 ),
  .pkt_o                                  ( pkt_rx_d1              )

);

assign rx_robot_run_w = pkt_rx.val && 
                        pkt_rx.sop && 
                        pkt_rx.ready;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    begin
      rx_dir_d1          <= 'd1;
    end
  else
    if( rx_robot_run_w )
      begin
        rx_dir_d1          <= rx_dir_w;
      end

eth_pkt_demux #( 

  .IF_PROPERTIES                          ( IF_PROPERTIES_RX  ),
  .TX_DIR                                 ( RX_DIR_CNT        ),
  .USE_DELAY                              ( 1                 )

) rx_demux (
  
  .rst_i                                  ( rst_i             ),
  .tx_dir_mask_i                          ( rx_dir_d1         ),
  .pkt_i                                  ( pkt_rx_d1         ),
  .pkt_o                                  ( pkt_rx_dmx        )

);


// drop всегда готов принимать пакеты
assign pkt_rx_dmx[RX_DIR_DROP].ready = 1'b1;







rx_cpu rx_cpu(
  .rst_i                                  ( rst_i                   ),
  // Network side
  .pkt_i                                  ( pkt_rx_dmx[RX_DIR_CPU]  ),
  .pkt_size_i                             ( pkt_rx_stat_w.pkt_size  ),
  .cpu_mtu_i                              ( nic_if.mtu              ),
  .pkt_wa_o                               ( dir_cpu_wa              ),  
  // CPU side
  .pkt_o                                  ( pkt_to_cpu_o            )
);




tx_cpu tx_cpu_buf(
  .clk_i                                  ( clk_i            ), 
  .rst_i                                  ( rst_i            ),   
  .pkt_i                                  ( pkt_from_cpu_i   ),
  .pkt_o                                  ( pkt_tx_o         )
);








endmodule
