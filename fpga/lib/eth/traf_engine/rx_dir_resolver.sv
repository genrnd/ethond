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

/*
  Модуль, который по статусу пакета и различным настройкам понимает,
  куда надо переслать этот пакет. По факту просто вынесли это из 
  traf_engine.

*/

import xge_rx::*;

module rx_dir_resolver
#( 
  parameter DIR_CNT  = xge_rx::RX_DIR_CNT
)
(  
  input        pkt_rx_info_t             pkt_rx_stat_i,
  input                                  dir_cpu_wa_i,  
  output logic [DIR_CNT-1:0]             rx_dir_o
);

logic         req_dir_cpu;
logic         bad_pkt;





assign bad_pkt  = ( pkt_rx_stat_i.crc_err  ) || 
                  ( pkt_rx_stat_i.runt     ) || 
                  ( pkt_rx_stat_i.oversize );

            
assign  req_dir_cpu = ( pkt_rx_stat_i.broadcast || 
                        pkt_rx_stat_i.multicast || 
                        pkt_rx_stat_i.usercast    ) &&
                       !bad_pkt ;




always_comb
  begin
    rx_dir_o                = '0;
    rx_dir_o[RX_DIR_CPU]    =  ( req_dir_cpu && dir_cpu_wa_i );
    rx_dir_o[RX_DIR_DROP]   = ~( req_dir_cpu && dir_cpu_wa_i );
  end


endmodule
