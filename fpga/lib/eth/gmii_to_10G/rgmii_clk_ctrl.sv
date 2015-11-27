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

module rgmii_clk_ctrl(
  
  input               rx_clk_i,
  input               rst_rx_clk_i,
  
  input               rx_sel_1000m_i,
  output  logic       rx_clk_en_o,

  input               tx_clk_i,
  input               rst_tx_clk_i,
  
  input               tx_sel_1000m_i,
  output  logic       tx_clk_en_o

);

// RX

logic rx_clk_div2;

always_ff @( posedge rx_clk_i or posedge rst_rx_clk_i )
  if( rst_rx_clk_i )
    rx_clk_div2 <= 1'b0;
  else
    rx_clk_div2 <= !rx_clk_div2;

always_ff @( posedge rx_clk_i or posedge rst_rx_clk_i )
  if( rst_rx_clk_i )
    rx_clk_en_o <= 1'b0;
  else
    rx_clk_en_o <= ( rx_sel_1000m_i ) ? ( 1'b1 ) : ( rx_clk_div2 );


// TX

logic tx_clk_div2;

always_ff @( posedge tx_clk_i or posedge rst_tx_clk_i )
  if( rst_tx_clk_i )
    tx_clk_div2 <= 1'b0;
  else
    tx_clk_div2 <= !tx_clk_div2;

always_ff @( posedge tx_clk_i or posedge rst_tx_clk_i )
  if( rst_tx_clk_i )
    tx_clk_en_o <= 1'b0;
  else
    tx_clk_en_o <= ( tx_sel_1000m_i ) ? ( 1'b1 ) : ( tx_clk_div2 );

endmodule
