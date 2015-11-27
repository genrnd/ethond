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

interface eth_pkt_if
#
( 
  parameter eth_pkt_if_t IF_PROPERTIES = eth_pkt_lib::DEFAULT_PROPERTIES,
  parameter IF_TYPE                    = "10G"
)
(

  input clk

);

  localparam D_WIDTH       = get_if_data_width(  IF_PROPERTIES ); 
  localparam MOD_WIDTH     = get_if_mod_width(   IF_PROPERTIES );
  localparam TUSER_W       = get_if_tuser_width( IF_PROPERTIES, 1 ); 
  
  logic [D_WIDTH-1:0]     data;
  logic                   sop;
  logic                   eop;
  logic [MOD_WIDTH-1:0]   mod;
  logic                   val;
  logic                   ready;
  logic [TUSER_W-1:0]     tuser;

  modport i( input clk, data, sop, eop, mod, val, tuser, output ready );
  
  modport o( output data, sop, eop, mod, val, tuser, input clk, ready );
  
  // внутренне счетчики интерфейса для подсчитывания количества пакетов/байт.
  // может быть удобно при отладке

// synthesis translate_off
  int                  cur_bytes_l2;
  // скорость данных в mbps
  real                 rate_l2;
  int                  tick_cnt;
  int                  total_byte_cnt_l2;
  int                  total_pkt_cnt;
  int                  sop_eop_cnt;

  initial
    begin
      cur_bytes_l2      = 0;
      tick_cnt          = 0;
      total_byte_cnt_l2 = 0;
      total_pkt_cnt     = 0;
      forever
        begin
          tick_cnt = tick_cnt + 1'd1;

          if( ready ) 
            begin

              cur_bytes_l2 = val ? ( eop ? ( ( mod == 'd0 ) ? ( D_WIDTH/8 + 'd4 ) : ( mod + 'd4 )  ) : ( D_WIDTH/8 ) ) : 'd0;

              total_byte_cnt_l2 = total_byte_cnt_l2 + cur_bytes_l2;
              
              // FIXME: расчет скорости должен зависеть от частоты интерфейса
              //        сейчас в etln это 62.5, поэтому захардкодили её так
              // константа 62.5 - это частота интерфейса в МГц
              rate_l2 = 62.5 * ( total_byte_cnt_l2 * 8.0 ) / ( tick_cnt );

              if( val && sop )
                total_pkt_cnt = total_pkt_cnt + 1'd1;
            end

          @( posedge clk );
        end
    end

  // В каждом пакете должно быть по одному sop и eop. За этим следит
  // sop_eop_cnt. При нормальной работе это значение должно быть или 0 или 1.
  // в остальных случаях что-то пошло не так.
  
  initial
    begin
      sop_eop_cnt = 0;

      forever
        begin
          if( val && ready )
            begin
              if( sop )
                sop_eop_cnt = sop_eop_cnt + 1'd1;
              
              if( eop )
                sop_eop_cnt = sop_eop_cnt - 1'd1;
            end

          @( posedge clk );
        end
    end

  assert property(
    @( posedge clk )
     ( ( sop_eop_cnt < 'd2 ) && ( sop_eop_cnt >= 'd0 ) )
  );
  
// synthesis translate_on
endinterface
