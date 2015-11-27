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
  package для содержания настроек интерфейса eth_pkt_if 
  и удобных функций для выдачи различных данных по этому интерфейсу.

*/
package eth_pkt_lib;
  
  // структурка с настройками интерфейса eth_pkt_if 
  typedef struct {
    // ширина данных
    int data_width;

    // ширина поля tuser 
    int tuser_width;
  } eth_pkt_if_t;
  
  parameter eth_pkt_if_t DEFAULT_PROPERTIES = '{ data_width  : 64, 
                                                 tuser_width : 0 };

  function int get_if_data_width( input eth_pkt_if_t if_property );
    return if_property.data_width;
  endfunction
  
  function int get_if_mod_width( input eth_pkt_if_t if_property );
    return $clog2( if_property.data_width/8 );
  endfunction
  
  function int get_if_fifo_width( input eth_pkt_if_t if_property );
    int payload_width;
    
    payload_width = 0;
    payload_width += get_if_data_width( if_property );
    payload_width += get_if_mod_width(  if_property );
    payload_width += 2; // for sop and eop
    payload_width += get_if_tuser_width( if_property, 0 );

    return payload_width;
  endfunction
  
  // one_for_zero - флаг:
  // если 0, то вернем текущий tuser_width
  // ecли 1, то если tuser_width = 0, то вернем 1, иначе просто tuser_width
  function int get_if_tuser_width( input eth_pkt_if_t if_property, input int one_for_zero = 0 );
    int ret;
    
    ret = if_property.tuser_width;

    if( one_for_zero )
      begin
        if( if_property.tuser_width == 0 )
          ret = 1;
      end
    
    return ret;
  endfunction
  
endpackage
