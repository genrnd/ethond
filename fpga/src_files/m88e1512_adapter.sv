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
  Модуль для мэпинга набора сигналов от 1G трансиверов m88e1512 
  в удобный интерфейс. Может сделать "хардварный" swap портов.

*/

module m88e1512_adapter #(

  // флаг о том, что надо перевернуть порты, т.к. при разводке
  // не получилось соблюсти, что порт A со стороны пользователя это 0 порт
  parameter PORT_SWAP = 0,
  
  // внутренний параметр, не менять
  parameter PORT_CNT  = 2 

)
(

  input                   trg_clk125m_i [PORT_CNT-1:0],

  input                   trg_rx_clk_i  [PORT_CNT-1:0],
  input   [3:0]           trg_rxd_i     [PORT_CNT-1:0],
  input                   trg_rx_ctrl_i [PORT_CNT-1:0],

  output                  trg_tx_clk_o  [PORT_CNT-1:0],
  output  [3:0]           trg_txd_o     [PORT_CNT-1:0],
  output                  trg_tx_ctrl_o [PORT_CNT-1:0],

  output                  trg_mdc_o     [PORT_CNT-1:0], 
  inout                   trg_mdio_io   [PORT_CNT-1:0],

  output                  trg_nreset_o  [PORT_CNT-1:0],

  output                  trg_ptpclk_o  [PORT_CNT-1:0],
  input                   trg_ptp_int   [PORT_CNT-1:0], 
  inout                   trg_ptp_io    [PORT_CNT-1:0],

  m88e1512_if.adapter     trg_if        [PORT_CNT-1:0]
);

genvar g;

generate
  for( g = 0; g < PORT_CNT; g++ )
    begin : trg_wires

      localparam PORT_IN = ( PORT_SWAP ) ? ( ( g == 0 ) ? ( 1 ) : ( 0 ) ) : ( g );

      assign trg_if[g].clk125m       = trg_clk125m_i[PORT_IN];
                                      
      assign trg_if[g].rx_clk        = trg_rx_clk_i [PORT_IN];
      assign trg_if[g].rx_data       = trg_rxd_i    [PORT_IN];   
      assign trg_if[g].rx_ctrl       = trg_rx_ctrl_i[PORT_IN];

      assign trg_tx_clk_o [PORT_IN]  = trg_if[g].tx_clk; 
      assign trg_txd_o    [PORT_IN]  = trg_if[g].tx_data;
      assign trg_tx_ctrl_o[PORT_IN]  = trg_if[g].tx_ctrl;

      assign trg_mdc_o    [PORT_IN]  = trg_if[g].mdc;

      // мы должны просто переназначить сигнал. assign нельзя использовать
      // т.к. это bideriction interface
      tran mdio_assign( trg_mdio_io[PORT_IN], trg_if[g].mdio );

      assign trg_nreset_o [PORT_IN]  = trg_if[g].nreset;

      assign trg_ptpclk_o [PORT_IN]  = trg_if[g].ptpclk;
      assign trg_if[g].ptp_int       = trg_ptp_int[PORT_IN]; 
      tran  ptp_assign( trg_ptp_io[PORT_IN], trg_if[g].ptp_io );

    end
endgenerate

endmodule
