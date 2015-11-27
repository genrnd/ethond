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
  Модуль пакетной фифшоки, имеет огромное количество параметров, 
  желательно именно ее использовать для буферизации пакетов.

*/

import eth_pkt_lib::*;

module eth_pkt_fifo
#
( 
  parameter eth_pkt_if_t IF_PROPERTIES = eth_pkt_lib::DEFAULT_PROPERTIES,
  parameter AWIDTH            = 11,
  parameter SAFE_WORDS        = 50,
  parameter DUAL_CLOCK        = 1,

  // внимание: после переезда на использование ready SHOWAHEAD всегда должен быть ON!
  parameter SHOWAHEAD         = "ON",
  parameter LPM_HINT          = "RAM_BLOCK_TYPE=M20K",

  // сигнал, использовать ли !wr_almost_full в качестве ready интерфейса wr_pkt_i
  // если 0, то ready всегда будет в 1
  // если 1, то берем инверсию ALMOST_FULL 
  parameter USE_WR_ALMOST_FULL_LIKE_WR_PKT_READY = 0,

  parameter DWIDTH            = get_if_data_width( IF_PROPERTIES ), 
  parameter BYTES_IN_WORD     = DWIDTH/8, 
  parameter EMPTY_BYTES_WIDTH = AWIDTH + $clog2( BYTES_IN_WORD )
)
(
 
  input                                    rst_i,
  
  eth_pkt_if                               wr_pkt_i,

  eth_pkt_if                               rd_pkt_o,
  
  output     logic                         rd_empty_o,
  output     logic                         wr_almost_full_o,
  output     logic [AWIDTH-1:0]            usedw_o,
  output     logic [EMPTY_BYTES_WIDTH-1:0] empty_bytes_o

);
localparam FIFO_DWIDTH       = get_if_fifo_width( IF_PROPERTIES );
localparam ALMOST_FULL_WORDS = 2**AWIDTH - 1 - SAFE_WORDS; 

logic              pkt_fifo_rdempty;
logic [AWIDTH-1:0] pkt_fifo_rdusedw;
logic              pkt_fifo_wrfull;
logic [AWIDTH-1:0] pkt_fifo_wrusedw;
logic [AWIDTH-1:0] pkt_fifo_wremptyw;

always_ff @( posedge wr_pkt_i.clk or posedge rst_i )
  if( rst_i )
    wr_almost_full_o <= 1'b0;
  else
    if( pkt_fifo_wrfull )
      wr_almost_full_o <= 1'b1;
    else
      if( pkt_fifo_wrusedw > ALMOST_FULL_WORDS ) 
        wr_almost_full_o <= 1'b1;
      else
        wr_almost_full_o <= 1'b0;

assign rd_empty_o = pkt_fifo_rdempty;
assign usedw_o    = pkt_fifo_wrusedw;

generate
  begin
    if( USE_WR_ALMOST_FULL_LIKE_WR_PKT_READY )
      assign wr_pkt_i.ready = !wr_almost_full_o;
    else
      assign wr_pkt_i.ready = 1'b1;
  end
endgenerate

always_ff @( posedge wr_pkt_i.clk or posedge rst_i )
  if( rst_i )
    pkt_fifo_wremptyw <= '0;
  else
    if( pkt_fifo_wrfull || ( pkt_fifo_wrusedw > ALMOST_FULL_WORDS ) )
      pkt_fifo_wremptyw <= '0;
    else
      pkt_fifo_wremptyw <= ALMOST_FULL_WORDS - pkt_fifo_wrusedw;

// converting empty words to empty_bytes
assign empty_bytes_o = pkt_fifo_wremptyw << $clog2( BYTES_IN_WORD );

logic [FIFO_DWIDTH-1:0] fifo_wr_data_w;
logic [FIFO_DWIDTH-1:0] fifo_rd_data_w;
logic                   fifo_wr_req;
logic                   fifo_rd_req;

assign fifo_wr_data_w = { wr_pkt_i.tuser, wr_pkt_i.data, wr_pkt_i.sop, wr_pkt_i.eop, wr_pkt_i.mod };
assign fifo_wr_req    = wr_pkt_i.val && wr_pkt_i.ready;


assign { rd_pkt_o.tuser, rd_pkt_o.data, rd_pkt_o.sop, rd_pkt_o.eop, rd_pkt_o.mod } = fifo_rd_data_w;
assign fifo_rd_req  = rd_pkt_o.ready && rd_pkt_o.val;
assign rd_pkt_o.val = !pkt_fifo_rdempty;

generate
  if( DUAL_CLOCK == 1 )
    begin
      cge_pkt_fifo 
      #( 
        .DWIDTH                                 ( FIFO_DWIDTH         ), 
        .AWIDTH                                 ( AWIDTH              ),
        .SHOWAHEAD                              ( SHOWAHEAD           ),
        .LPM_HINT                               ( LPM_HINT            )
      ) pkt_fifo
      (
        .aclr                                   ( rst_i               ),
        .data                                   ( fifo_wr_data_w      ),

        .rdclk                                  ( rd_pkt_o.clk        ), 
        .rdreq                                  ( fifo_rd_req         ),

        .wrclk                                  ( wr_pkt_i.clk        ),
        .wrreq                                  ( fifo_wr_req         ),

        .q                                      ( fifo_rd_data_w      ),

        .rdempty                                ( pkt_fifo_rdempty    ),
        .rdusedw                                ( pkt_fifo_rdusedw    ),
        .wrfull                                 ( pkt_fifo_wrfull     ),
        .wrusedw                                ( pkt_fifo_wrusedw    )
      );
    end
  else
    begin

      cge_pkt_fifo_one_clock 
      #( 
        .DWIDTH                                 ( FIFO_DWIDTH         ), 
        .AWIDTH                                 ( AWIDTH              ),
        .SHOWAHEAD                              ( SHOWAHEAD           ),
        .LPM_HINT                               ( LPM_HINT            )
      ) pkt_fifo(
        .aclr                                   ( rst_i               ),
        .clock                                  ( wr_pkt_i.clk        ),

        .data                                   ( fifo_wr_data_w      ),

        .rdreq                                  ( fifo_rd_req         ),
        .wrreq                                  ( fifo_wr_req         ),
        
        .empty                                  ( pkt_fifo_rdempty    ),
        .full                                   ( pkt_fifo_wrfull     ),

        .q                                      ( fifo_rd_data_w      ),

        .usedw                                  ( pkt_fifo_wrusedw    )
      );

      assign pkt_fifo_rdusedw = pkt_fifo_wrusedw;

    end
endgenerate

// Some assertions
// synthesis translate_off

// Не надо писать в совсем полную фифошку
assert property
(
  @( posedge wr_pkt_i.clk ) disable iff( rst_i )
   ( ( ( fifo_wr_req ) && ( pkt_fifo_wrfull ) ) == 1'b0 )   

);

// Не надо читать из пустой фифошки
assert property
(
  @( posedge rd_pkt_o.clk ) disable iff( rst_i )
   ( ( ( fifo_rd_req ) && ( pkt_fifo_rdempty ) ) == 1'b0 )   

);

initial
  begin
    if( SHOWAHEAD == "OFF" )
      begin
        $display( "%m: parameter SHOWAHEAD = %s are not allowed!", SHOWAHEAD );
        $fatal();
      end
   end


// synthesis translate_on


endmodule
