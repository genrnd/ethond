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
  Модуль для изменения контрольных сигналов пакетного интерфейса. 
  Может быть удобным, если надо ready/val сложить по И/ИЛИ с чем-то.
*/

import eth_pkt_lib::*; 

module eth_pkt_if_control_changer
#( 
  
  parameter eth_pkt_if_t IF_PROPERTIES = eth_pkt_lib::DEFAULT_PROPERTIES,

  // как "добавить" ready
  // AND  - сложить по И
  // OR   - сложить по ИЛИ
  // NONE - ничего не делать 
  parameter READY_ACTION = "NONE",

  // как "добавить" val
  parameter VAL_ACTION   = "NONE"
)
(
  // сигнал ready, который мы хотим "подмешать"
  input        third_party_ready_i,
  
  // сигнал val, который мы хотим "подмешать"
  input        third_party_val_i,

  eth_pkt_if.i pkt_i,

  eth_pkt_if.o pkt_o

);

assign pkt_o.data  = pkt_i.data;
assign pkt_o.tuser = pkt_i.tuser;

assign pkt_o.sop   = pkt_i.sop; 
assign pkt_o.eop   = pkt_i.eop;
assign pkt_o.mod   = pkt_i.mod;
    
always_comb
  begin
    pkt_o.val   = pkt_i.val;
    pkt_i.ready = pkt_o.ready;

    if( VAL_ACTION == "AND" )
      pkt_o.val = pkt_i.val && third_party_val_i;

    if( VAL_ACTION == "OR" )
      pkt_o.val = pkt_i.val || third_party_val_i;
    
    if( READY_ACTION == "AND" )
      pkt_i.ready = pkt_o.ready && third_party_ready_i;
    
    if( READY_ACTION == "OR" )
      pkt_i.ready = pkt_o.ready || third_party_ready_i;
  end



endmodule
