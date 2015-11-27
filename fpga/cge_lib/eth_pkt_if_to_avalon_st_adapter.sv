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
  Конвертор eth_pkt_if в avalon-st.

  TODO: параметризация.
*/

module eth_pkt_if_to_avalon_st_adapter(

  eth_pkt_if.i    pkt_i,
  
  // avalon-st 
  output  [63:0]  st_sink_data,               
  output          st_sink_valid,              
  output          st_sink_startofpacket,      
  output          st_sink_endofpacket,        
  output  [2:0]   st_sink_empty, 
  input           st_sink_ready              

);

assign st_sink_data          = pkt_i.data;
assign st_sink_valid         = pkt_i.val;
assign st_sink_startofpacket = pkt_i.sop;
assign st_sink_endofpacket   = pkt_i.eop;
assign st_sink_empty         = ( pkt_i.mod == 'd0 ) ? ( 'd0 ) : ( 'd8 - pkt_i.mod );
assign pkt_i.ready           = st_sink_ready; 

endmodule
