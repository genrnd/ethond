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
  Просто обертка над статусной фифошкой с возможностью легкой
  параметризации. Аля eth_pkt_fifo.
*/

module stat_fifo_generic
#( parameter AWIDTH     = 9,
   parameter DWIDTH     = 64,
   parameter DUAL_CLOCK = 1,
   parameter SHOWAHEAD  = "ON",
   
   parameter SAFE_WORDS = 10,

   // выбор используемых блоков для создания памяти
   parameter LPM_HINT   = "RAM_BLOCK_TYPE=MLAB" 
)
(
  
  input                      rst_i,

  
  input                      wr_clk_i,
  input                      wr_req_i,
  input        [DWIDTH-1:0]  wr_data_i,

  input                      rd_clk_i,
  input                      rd_req_i,
  output logic [DWIDTH-1:0]  rd_data_o,
  
  output logic               rd_empty_o,
  output logic               wr_almost_full_o

);
localparam ALMOST_FULL_WORDS = 2**AWIDTH - 1 - SAFE_WORDS;

logic [AWIDTH-1:0] wrusedw;
logic              empty_w;
logic              full_w;

always_ff @( posedge wr_clk_i or posedge rst_i )
  if( rst_i )
    wr_almost_full_o <= 1'b0;
  else
    if( full_w )
      wr_almost_full_o <= 1'b1;
    else
      if( wrusedw > ALMOST_FULL_WORDS )
        wr_almost_full_o <= 1'b1;
      else
        wr_almost_full_o <= 1'b0;

assign rd_empty_o = empty_w;

generate
  if( DUAL_CLOCK == 1 )
    begin : g_dc
      cge_stat_fifo_dual_clk 
      #
      ( 
        .DWIDTH                                 ( DWIDTH               ),
        .AWIDTH                                 ( AWIDTH               ),
        .LPM_HINT                               ( LPM_HINT             ),
        .SHOWAHEAD                              ( SHOWAHEAD            )
      ) dcf
      (
        .aclr                                   ( rst_i                ),
        .data                                   ( wr_data_i            ),
        .rdclk                                  ( rd_clk_i             ),
        .rdreq                                  ( rd_req_i             ),
        .wrclk                                  ( wr_clk_i             ),
        .wrreq                                  ( wr_req_i             ),
        .q                                      ( rd_data_o            ),
        .rdusedw                                (                      ),
        .wrusedw                                ( wrusedw              ),
        .rdempty                                ( empty_w              ),
        .wrfull                                 ( full_w               )
      );
    end
  else
    begin : g_sf
      cge_stat_fifo  
      #
      ( 
        .DWIDTH                                 ( DWIDTH            ),
        .AWIDTH                                 ( AWIDTH            ),
        .LPM_HINT                               ( LPM_HINT          ),
        .SHOWAHEAD                              ( SHOWAHEAD         )
      ) scf
      (       
        .aclr                                   ( rst_i             ),
        .clock                                  ( wr_clk_i          ),
        .data                                   ( wr_data_i         ),
        
        .rdreq                                  ( rd_req_i          ),
        .wrreq                                  ( wr_req_i          ),

        .empty                                  ( empty_w           ),
        .full                                   ( full_w            ),
        
        .usedw                                  ( wrusedw           ), 
        .q                                      ( rd_data_o         )
      );
    end
endgenerate

// Some assertions
// synthesis translate_off

// Не надо писать в совсем полную фифошку

assert property
(
  @( posedge wr_clk_i ) disable iff ( rst_i )
   ( ( ( wr_req_i ) && ( full_w ) ) == 1'b0 )   
);

// Не надо читать из пустой фифошки
assert property
(
  @( posedge rd_clk_i ) disable iff ( rst_i )
   ( ( ( rd_req_i ) && ( empty_w ) ) == 1'b0 )   

);

// synthesis translate_on

endmodule
