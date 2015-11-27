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

// оригинальная идея в Phy_int.v в ядре с opencores
module gbe_phy_int(
  // RX clock domain (!)
  input               rx_clk_i,
  input               rst_rx_clk_i,
  
  input               rx_sel_1000m_i,

  // from RX PHY interface
  input        [7:0]  rx_d_i,
  input               rx_dv_i,
  input               rx_err_i,
  
  // to RX app 
  output logic [7:0]  gmii_rx_d_o,
  output logic        gmii_rx_dv_o,
  output logic        gmii_rx_err_o,
  
  // TX clock domain(!)
  input               tx_clk_i,
  input               rst_tx_clk_i,
  
  input               tx_sel_1000m_i,
  
  // from TX app 
  input        [7:0]  gmii_tx_d_i,
  input               gmii_tx_en_i,
  
  // to TX PHY 
  output logic [7:0]  tx_d_o,
  output logic        tx_en_o,
  output logic        tx_err_o
  
);

// RX

logic [7:0]   rx_d_d1;
logic         rx_dv_d1;
logic         rx_err_d1;

logic [7:0]   rx_d_d2;
logic         rx_dv_d2;
logic         rx_err_d2;

logic         rx_mii_pos;

always_ff @( posedge rx_clk_i or posedge rst_rx_clk_i )
  if( rst_rx_clk_i )
    begin
      rx_d_d1   <= '0;
      rx_dv_d1  <= '0;
      rx_err_d1 <= '0;

      rx_d_d2   <= '0;
      rx_dv_d2  <= '0;
      rx_err_d2 <= '0;
    end
  else
    begin
      rx_d_d1   <= rx_d_i; 
      rx_dv_d1  <= rx_dv_i; 
      rx_err_d1 <= rx_err_i; 

      rx_d_d2   <= rx_d_d1;   
      rx_dv_d2  <= rx_dv_d1;  
      rx_err_d2 <= rx_err_d1; 
    end

always_ff @( posedge rx_clk_i or posedge rst_rx_clk_i )
  if( rst_rx_clk_i )
    gmii_rx_dv_o <= 1'b0;
  else
    gmii_rx_dv_o <= rx_dv_d2;

always_ff @( posedge rx_clk_i or posedge rst_rx_clk_i )
  if( rst_rx_clk_i )
    gmii_rx_err_o <= 1'b0;
  else
    gmii_rx_err_o <= rx_err_d2;

always_ff @( posedge rx_clk_i or posedge rst_rx_clk_i )
  if( rst_rx_clk_i )
    rx_mii_pos <= 1'b0;
  else
    if( rx_dv_d1 )
      rx_mii_pos <= ~rx_mii_pos;
    else
      rx_mii_pos <= 1'b0;

always_ff @( posedge rx_clk_i or posedge rst_rx_clk_i )
  if( rst_rx_clk_i )
    gmii_rx_d_o <= 1'b0;
  else
    if( rx_sel_1000m_i && rx_dv_d2 ) 
      gmii_rx_d_o <= rx_d_d2;
    else
      if( rx_dv_d1 && rx_mii_pos )
        gmii_rx_d_o <= { rx_d_d1[3:0], rx_d_d2[3:0] };



// TX
logic [7:0]   gmii_tx_d_d1;
logic         gmii_tx_en_d1;

logic         tx_mii_pos;


always_ff @( posedge tx_clk_i or posedge rst_tx_clk_i )
  if( rst_tx_clk_i )
    begin
      gmii_tx_d_d1  <= '0;
      gmii_tx_en_d1 <= 1'b0;
    end
  else
    begin
      gmii_tx_d_d1  <= gmii_tx_d_i;
      gmii_tx_en_d1 <= gmii_tx_en_i;
    end


always_ff @( posedge tx_clk_i or posedge rst_tx_clk_i )
  if( rst_tx_clk_i )
    tx_mii_pos <= 1'b0;
  else
    if( gmii_tx_en_d1 )
      tx_mii_pos <= ~tx_mii_pos;
    else
      tx_mii_pos <= 1'b0;

always_ff @( posedge tx_clk_i or posedge rst_tx_clk_i )
  if( rst_tx_clk_i )
    tx_d_o <= '0;
  else
    if( gmii_tx_en_d1 ) 
      begin
        if( tx_sel_1000m_i )
          tx_d_o <= gmii_tx_d_d1;
        else
          tx_d_o <= ( tx_mii_pos == 1'b0 ) ? ( { 4'b0, gmii_tx_d_d1[3:0] } ) : 
                                             ( { 4'b0, gmii_tx_d_d1[7:4] } );
      end
    else
      begin
        tx_d_o <= 8'h0;
      end

always_ff @( posedge tx_clk_i or posedge rst_tx_clk_i )
  if( rst_tx_clk_i )
    tx_en_o <= 1'b0;
  else
    tx_en_o <= gmii_tx_en_d1;

// no error on transmit...
assign tx_err_o = 1'b0;

endmodule
