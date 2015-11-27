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
  Модуль для конвертации 8 битного 1G, 
  в 64 битный интерфейс, используемый (или близкий к этому) в 10G.

  Содержит часть из мак-ядра 1G (прием кадра, подсчет CRC), 
  конвертацию 8 -> 64, запись в fifo.
*/

module conv_1G_top #(
  parameter RX_EN           = 1,
  parameter TX_EN           = 1,
  parameter REDUCED_TX_FIFO = 0
)
(
  input                 Reset,
  input                 Clk_user,
                         
  // Phy interface         
  input                 Rx_clk,
  input         [7:0]   Rxd,
  input                 Rx_dv,
  input                 Rx_er,

  input                 Tx_clk, 
  output        [7:0]   Txd,
  output                Tx_en,
  output                Tx_er,

  input         [2:0]   RxSpeed,  
  input         [2:0]   TxSpeed, // скорости передачи/приема 10/100/1000  

  // to traf_engine rx
  input                 tr_en_fifo_full_i,
  output logic  [63:0]  pkt_conv_rx_data_o,
  output logic  [7:0]   pkt_conv_rx_status_o,
  output logic  [2:0]   pkt_conv_rx_error_o,
  output logic  [15:0]  pkt_conv_rx_len_o,
  output logic          pkt_conv_rx_val_o,

  // from traf_engine tx
  input  logic  [63:0]  pkt_conv_tx_data_i,
  input  logic  [2:0]   pkt_conv_tx_mod_i,
  input  logic          pkt_conv_tx_sop_i,
  input  logic          pkt_conv_tx_eop_i,
  input  logic          pkt_conv_tx_val_i,
  output logic          conv_tx_fifo_full_o
);
// interface clk signals
logic        rx_clk;
logic        tx_clk;
logic        clk_sys;

logic        rx_clk_en;
logic        tx_clk_en;

logic        rst_rx_clk;
logic        rst_tx_clk;

logic        rx_sel_1000m;
logic        tx_sel_1000m;

logic        rx_sel_1000m_resync;
logic        tx_sel_1000m_resync;

logic  [7:0] gmii_rx_d_w;
logic        gmii_rx_dv_w; 
logic        gmii_rx_err_w; 

logic  [7:0] gmii_tx_d_w;
logic        gmii_tx_en_w; 

assign rx_clk = Rx_clk;
assign tx_clk = Tx_clk;

assign clk_sys = Clk_user;

// FIXME: use reset synchronizer
assign rst_rx_clk = Reset;
assign rst_tx_clk = Reset;

assign rx_sel_1000m = RxSpeed[2];
assign tx_sel_1000m = TxSpeed[2];

bit_resync br_rx_sel_1000m(
  .clk_i                                  ( rx_clk              ),
  .rst_i                                  ( rst_rx_clk          ),

  .d_i                                    ( rx_sel_1000m        ),
  .d_o                                    ( rx_sel_1000m_resync )
);

bit_resync br_tx_sel_1000m(
  .clk_i                                  ( tx_clk              ),
  .rst_i                                  ( rst_tx_clk          ),

  .d_i                                    ( tx_sel_1000m        ),
  .d_o                                    ( tx_sel_1000m_resync )
);

gbe_phy_int phy_int(

  .rx_clk_i                               ( rx_clk            ),
  .rst_rx_clk_i                           ( rst_rx_clk        ),
    
  .tx_clk_i                               ( tx_clk            ),
  .rst_tx_clk_i                           ( rst_tx_clk        ),
    
  .rx_sel_1000m_i                         ( rx_sel_1000m_resync ),
  .tx_sel_1000m_i                         ( tx_sel_1000m_resync ),

    // from RX PHY interface
  .rx_d_i                                 ( Rxd              ),
  .rx_dv_i                                ( Rx_dv            ),
  .rx_err_i                               ( Rx_er            ),
    
    // to RX app 
  .gmii_rx_d_o                            ( gmii_rx_d_w       ),
  .gmii_rx_dv_o                           ( gmii_rx_dv_w      ),
  .gmii_rx_err_o                          ( gmii_rx_err_w     ),
    
    // from TX app 
  .gmii_tx_d_i                            ( gmii_tx_d_w       ),
  .gmii_tx_en_i                           ( gmii_tx_en_w      ),
    
    // to TX PHY 
  .tx_d_o                                 ( Txd              ),
  .tx_en_o                                ( Tx_en            ),
  .tx_err_o                               ( Tx_er            )
  
);

rgmii_clk_ctrl clk_ctrl(
  
  .rx_clk_i                               ( rx_clk              ),
  .rst_rx_clk_i                           ( rst_rx_clk          ),
    
  .rx_sel_1000m_i                         ( rx_sel_1000m_resync ),
  .rx_clk_en_o                            ( rx_clk_en           ),

  .tx_clk_i                               ( tx_clk              ),
  .rst_tx_clk_i                           ( rst_tx_clk          ),
    
  .tx_sel_1000m_i                         ( tx_sel_1000m_resync ),
  .tx_clk_en_o                            ( tx_clk_en           )

);

generate
  if( RX_EN )
    begin
      conv_1G_rx rx(
        .rx_clk_i                   ( rx_clk                ),
        .rx_clk_en_i                ( rx_clk_en             ),

        .rst_rx_clk_i               ( rst_rx_clk            ),

        .clk_sys_i                  ( clk_sys               ),

        .rx_d_i                     ( gmii_rx_d_w           ),
        .rx_dv_i                    ( gmii_rx_dv_w          ),
        .rx_err_i                   ( gmii_rx_err_w         ),

        // XFACE
        .tr_en_fifo_full_i          ( tr_en_fifo_full_i     ),
        .pkt_rx_data_o              ( pkt_conv_rx_data_o    ),
        .pkt_rx_status_o            ( pkt_conv_rx_status_o  ),
        .pkt_rx_error_o             ( pkt_conv_rx_error_o   ),
        .pkt_rx_len_o               ( pkt_conv_rx_len_o     ),
        .pkt_rx_val_o               ( pkt_conv_rx_val_o     )
      );
    end
  else
    begin
      assign pkt_conv_rx_data_o    = '0; 
      assign pkt_conv_rx_status_o  = '0; 
      assign pkt_conv_rx_error_o   = '0; 
      assign pkt_conv_rx_len_o     = '0; 
      assign pkt_conv_rx_val_o     = '0; 
    end
endgenerate

generate
  if( TX_EN )
    begin
      conv_1G_tx #( 
        .REDUCED_FIFO               ( REDUCED_TX_FIFO       ) 
      ) tx (
        .tx_clk_i                   ( tx_clk                ),
        .tx_clk_en_i                ( tx_clk_en             ),
        .rst_tx_clk_i               ( rst_tx_clk            ),

        .clk_sys_i                  ( clk_sys               ),

        // PHY interface
        .TxD                        ( gmii_tx_d_w           ),
        .TxEn                       ( gmii_tx_en_w          ),

        .tx_fifo_full_o             ( conv_tx_fifo_full_o   ),
        .pkt_tx_data_i              ( pkt_conv_tx_data_i    ),
        .pkt_tx_mod_i               ( pkt_conv_tx_mod_i     ),
        .pkt_tx_sop_i               ( pkt_conv_tx_sop_i     ),
        .pkt_tx_eop_i               ( pkt_conv_tx_eop_i     ),
        .pkt_tx_val_i               ( pkt_conv_tx_val_i     )
      );
    end
  else
    begin
      assign gmii_tx_d_w         = 8'h0;
      assign gmii_tx_en_w        = 1'b0;
      assign conv_tx_fifo_full_o = 1'b0; 
    end
endgenerate

endmodule
