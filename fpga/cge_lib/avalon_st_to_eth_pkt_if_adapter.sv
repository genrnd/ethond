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
  Конвертор avalon-st в eth_pkt_if.
  
  TODO: параметризация.

*/
module avalon_st_to_eth_pkt_if_adapter(
  
  // avalon-st 
  input  [63:0]  st_source_data,               
  input          st_source_valid,              
  input          st_source_startofpacket,      
  input          st_source_endofpacket,        
  input  [2:0]   st_source_empty, 
  output         st_source_ready,              

  eth_pkt_if.o   pkt_o

);

assign pkt_o.data      = st_source_data;
assign pkt_o.val       = st_source_valid;
assign pkt_o.sop       = st_source_startofpacket;
assign pkt_o.eop       = st_source_endofpacket;
assign pkt_o.mod       = ( st_source_empty == 'd0 ) ? ( 'd0 ) : ( 'd8 - st_source_empty );
assign st_source_ready = pkt_o.ready;

endmodule
