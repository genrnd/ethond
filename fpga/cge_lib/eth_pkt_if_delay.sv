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
  Модуль для задержки интерфейса eth_pkt_if
  на нужное количество тактов.
 
*/

import eth_pkt_lib::*;

module eth_pkt_if_delay #( 
  parameter eth_pkt_if_t IF_PROPERTIES = eth_pkt_lib::DEFAULT_PROPERTIES,

  // задерживать на это количество тактов
  parameter DELAY          = 1,
  parameter PIPELINE_READY = 0
)
(
  input        rst_i,

  eth_pkt_if.i pkt_i,

  eth_pkt_if.o pkt_o

);

localparam D_WIDTH     = get_if_data_width(   IF_PROPERTIES ); 
localparam MOD_WIDTH   = get_if_mod_width(    IF_PROPERTIES );
localparam TUSER_WIDTH = get_if_tuser_width(  IF_PROPERTIES );

generate
  if( DELAY == 0 )
    begin
      assign pkt_o.data  = pkt_i.data; 
      assign pkt_o.sop   = pkt_i.sop;
      assign pkt_o.eop   = pkt_i.eop;
      assign pkt_o.mod   = pkt_i.mod;
      assign pkt_o.val   = pkt_i.val;
      assign pkt_o.tuser = pkt_i.tuser;
      assign pkt_i.ready = pkt_o.ready;
    end
  else
    begin : eth_delay_pipe
      altera_avalon_st_pipeline_stage #(
          .SYMBOLS_PER_BEAT                       ( D_WIDTH/8         ),
          .BITS_PER_SYMBOL                        ( 8                 ),
          .USE_PACKETS                            ( 1                 ),
          .USE_EMPTY                              ( 1                 ),
          .PIPELINE_READY                         ( PIPELINE_READY    ),
          
          // используем CHANNEL вместо TUSER
          .CHANNEL_WIDTH                          ( TUSER_WIDTH       ),

          // не используем
          .ERROR_WIDTH                            ( 0                 ),
          
          // надо для захватывания sop и eop
          .PACKET_WIDTH                           ( 2                 ),
          // используем empty как MOD
          .EMPTY_WIDTH                            ( MOD_WIDTH         )
        ) eth_d (
          .clk                                    ( pkt_i.clk         ),
          .reset                                  ( rst_i             ),

          .in_ready                               ( pkt_i.ready       ),
          .in_valid                               ( pkt_i.val         ),
          .in_data                                ( pkt_i.data        ),
          .in_channel                             ( pkt_i.tuser       ),
          .in_error                               ( 1'b0              ),
          .in_startofpacket                       ( pkt_i.sop         ),
          .in_endofpacket                         ( pkt_i.eop         ),
          .in_empty                               ( pkt_i.mod         ),

          .out_ready                              ( pkt_o.ready       ),
          .out_valid                              ( pkt_o.val         ),
          .out_data                               ( pkt_o.data        ),
          .out_channel                            ( pkt_o.tuser       ),
          .out_error                              (                   ),
          .out_startofpacket                      ( pkt_o.sop         ),
          .out_endofpacket                        ( pkt_o.eop         ),
          .out_empty                              ( pkt_o.mod         )
      );

      // synthesys translate_off
      initial
        begin
          if( DELAY > 1 )
            begin
              $display("%m: parameter DELAY=%d not supported!", DELAY );
              $fatal();
            end
        end
      // synthesys translate_on
    end
endgenerate


endmodule
