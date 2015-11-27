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
  Содержит интерфейсы с физикой: mx_dual_phy_iface, которая
  из xgmii/gmii выцепляет данные в зависимости от выбранной скорости
  и передает на mx_traf_engine, которая уже и обрабатывает пакеты.
*/


module mx_main_engine
(
  
  input                              clk_156m25_i,
  input                              rst_i, 
  // 1G PHY
  gmii_phy_if.phy                    gmii_if,

  // Control/status of traf_gen, etc
  nic_ctrl_if.app                    nic_if,

  // network stack 
  eth_pkt_if.i                       pkt_from_cpu_i,
  eth_pkt_if.o                       pkt_to_cpu_o

);

rx_engine_if                      pkt_rx( );

eth_pkt_if #( .IF_TYPE( "10G" ) ) pkt_tx( clk_156m25_i );

mx_dual_phy_iface 
#(
  .XGE_RX_EN                              ( 0                 ),
  .XGE_TX_EN                              ( 0                 ),
  .GBE_RX_EN                              ( 1                 ),
  .GBE_TX_EN                              ( 1                 ) 

) xgbe_phy (
  
  .rst_i                                  ( rst_i             ),
    // 10G tx interface
  .xgmii_clk_i                            ( clk_156m25_i      ),

  .xgmii_rxd_i                            (        ),
  .xgmii_rxc_i                            (        ),
    
  .xgmii_txd_o                            (        ),
  .xgmii_txc_o                            (        ),
    
  .gmii_if                                ( gmii_if           ),
  .pkt_rx_o                               ( pkt_rx            ),
    // to tx_engine
  .pkt_tx_i                               ( pkt_tx            )

);

mx_traf_engine 
 te (
  .clk_i                                  ( clk_156m25_i      ),
  .rst_i                                  ( rst_i             ),
  .nic_if                                 ( nic_if            ),
  // from MAC core
  .pkt_rx_i                               ( pkt_rx            ),
  // tx_interface
  .pkt_tx_o                               ( pkt_tx            ),  
  // network stack
  .pkt_to_cpu_o                           ( pkt_to_cpu_o      ),
  .pkt_from_cpu_i                         ( pkt_from_cpu_i    )
);


endmodule
