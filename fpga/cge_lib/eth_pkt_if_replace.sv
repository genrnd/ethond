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
  Модуль для подмены чего-то в пакетном интерфейсе.

*/

import eth_pkt_lib::*; 

module eth_pkt_if_replace
#( 
  parameter eth_pkt_if_t IF_PROPERTIES = eth_pkt_lib::DEFAULT_PROPERTIES,

  // internal parameters
  parameter D_WIDTH     = get_if_data_width(  IF_PROPERTIES ),
  parameter TUSER_WIDTH = get_if_tuser_width( IF_PROPERTIES )
)
(
  
  input [D_WIDTH-1:0]     next_data_i,
  input                   next_data_replace_en_i,

  input [TUSER_WIDTH-1:0] next_tuser_i,
  input                   next_tuser_replace_en_i,

  eth_pkt_if.i pkt_i,

  eth_pkt_if.o pkt_o

);

assign pkt_o.data  = ( next_data_replace_en_i  ) ? ( next_data_i  ) : ( pkt_i.data  );
assign pkt_o.tuser = ( next_tuser_replace_en_i ) ? ( next_tuser_i ) : ( pkt_i.tuser );

assign pkt_o.sop   = pkt_i.sop; 
assign pkt_o.eop   = pkt_i.eop;
assign pkt_o.mod   = pkt_i.mod;
assign pkt_o.val   = pkt_i.val;
    
assign pkt_i.ready = pkt_o.ready;


endmodule
