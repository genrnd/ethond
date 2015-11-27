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





module etn_main #(
  // внутренний параметр. изменять не надо!
  parameter PORT_CNT = 2 
)
(
  input                         clk_62_5m_i,
  input                         clk_125m_i,

  etnsoc_if.app                 etnsoc_if,

  netdma_cpu_interface          netdma_cpu_if0,
  netdma_cpu_interface          netdma_cpu_if1,
  netdma_mm_write_interface     netdma_write_if0,
  netdma_mm_write_interface     netdma_write_if1,
  netdma_mm_read_interface      netdma_read_if0,
  netdma_mm_read_interface      netdma_read_if1,

  m88e1512_if.trg               trg_if [PORT_CNT-1:0]
);

logic clk_sys;
logic main_clk_w [PORT_CNT-1:0];

// Interface to/from CPU
eth_pkt_if #( .IF_TYPE( "10G" ) ) pkt_to_cpu_w    [PORT_CNT-1:0] ( clk_sys );
eth_pkt_if #( .IF_TYPE( "10G" ) ) pkt_from_cpu_w  [PORT_CNT-1:0] ( clk_sys );

mx_xgbe_ctrl_if xgbe_ctrl_if[PORT_CNT-1:0] ( );

mdio_if         mdio_if [PORT_CNT-1:0] ( clk_125m_i );

gmii_phy_if     gmii_if [PORT_CNT-1:0] ( );

csr_if #(
  .A_WIDTH              ( 10        ),
  .D_WIDTH              ( 16        ),
  .BE_WIDTH             ( 2         )
) main_reg_csr_if( 
  .clk                  ( clk_sys   )
);


assign clk_sys       = clk_62_5m_i;

assign main_clk_w[0] = clk_sys;
assign main_clk_w[1] = clk_sys;

genvar g;
generate
  for( g = 0; g < 2; g++ )
    begin : port
      mdio_wrapper #( 
        .ENABLE_FIRMWARE_LOAD                   ( 0                  ) 
      ) mdio(
        .clk_i                                  ( clk_125m_i         ),          
        .mdio_if                                ( mdio_if[g]         ),          
        .mdio_io                                ( trg_if[g].mdio     ),
        .mdc_o                                  ( trg_if[g].mdc      )
      );
    end
endgenerate    

mx_app_anlz_wrapper #( 
  .PORT_CNT                               ( PORT_CNT                              ) 
) anlz(
  .main_clk_i                             ( main_clk_w[PORT_CNT-1:0]              ),

    
    // 1G PHY
  .gmii_if                                ( gmii_if[PORT_CNT-1:0]                 ),

  .main_reg_csr_if                        ( main_reg_csr_if.slave                 ),

  .mdio_if                                ( mdio_if                               ),
  .xgbe_ctrl_if                           ( xgbe_ctrl_if                          ),

  .pkt_from_cpu_i                         ( pkt_from_cpu_w                        ),
  .pkt_to_cpu_o                           ( pkt_to_cpu_w                          )

);

etnsoc2app etn2soc_adapter(
  .clk_i                                  ( clk_sys           ), 
  .etnsoc_if                              ( etnsoc_if         ),

  .main_reg_csr_if                        ( main_reg_csr_if   )
);


netdma_wrapper netdma_wrapper(
  .clk_i                                  ( clk_sys           ), 
  .netdma_cpu_if0                         ( netdma_cpu_if0    ),
  .netdma_cpu_if1                         ( netdma_cpu_if1    ),
  .netdma_write_if0                       ( netdma_write_if0  ),
  .netdma_write_if1                       ( netdma_write_if1  ),
  .netdma_read_if0                        ( netdma_read_if0   ),
  .netdma_read_if1                        ( netdma_read_if1   ),
    
  .pkt_to_cpu_i                           ( pkt_to_cpu_w      ),
  .pkt_from_cpu_o                         ( pkt_from_cpu_w    )
);




// *************** TRA RGMII *****************

logic       rx_clk  [PORT_CNT-1:0];
logic [3:0] rx_d    [PORT_CNT-1:0];
logic       rx_ctrl [PORT_CNT-1:0];

logic       tx_clk  [PORT_CNT-1:0];
logic [3:0] tx_d    [PORT_CNT-1:0];
logic       tx_ctrl [PORT_CNT-1:0];

generate
  for( g = 0; g < PORT_CNT; g++ )
    begin : trg_wires
      assign rx_clk[g]         = trg_if[g].rx_clk;
      assign rx_d[g]           = trg_if[g].rx_data;
      assign rx_ctrl[g]        = trg_if[g].rx_ctrl;

      assign trg_if[g].tx_clk  = tx_clk[g]; 
      assign trg_if[g].tx_data = tx_d[g];    
      assign trg_if[g].tx_ctrl = tx_ctrl[g];

      assign tx_clk[g]         = rx_clk[g];
      
      // unused now...
      assign trg_if[g].ptpclk  = 1'b0;
    end
endgenerate


logic [7:0] rx_gmii_data[PORT_CNT-1:0]/* synthesis keep */;
logic       rx_gmii_en  [PORT_CNT-1:0]/* synthesis keep */;
logic       rx_gmii_err [PORT_CNT-1:0]/* synthesis keep */;

logic [7:0] tx_gmii_data[PORT_CNT-1:0]/* synthesis keep */;
logic       tx_gmii_en  [PORT_CNT-1:0]/* synthesis keep */;
logic       tx_gmii_err [PORT_CNT-1:0]/* synthesis keep */;

generate
  for( g = 0; g < PORT_CNT; g++ )
    begin : t
      altera_tse_rgmii_module alt_rgmii(   
        .speed                                  ( 1'b1              ),

        .reset_rx_clk                           ( 1'b0              ),
        .reset_tx_clk                           ( 1'b0              ),
        .rx_clk                                 ( rx_clk[g]         ),
        .rgmii_in                               ( rx_d[g]           ),
        .rx_control                             ( rx_ctrl[g]        ),
        
        .tx_clk                                 ( tx_clk[g]         ),

        // outputs:
        .rgmii_out                              ( tx_d[g]           ),
        .tx_control                             ( tx_ctrl[g]        ),

        .gm_rx_d                                ( rx_gmii_data[g]   ),
        .gm_rx_dv                               ( rx_gmii_en[g]     ),
        
        .gm_tx_d                                ( tx_gmii_data[g]   ),
        .gm_tx_en                               ( tx_gmii_en[g]     ),
        
        .m_tx_d                                 ( '0    ),
        .m_tx_en                                ( 1'b0  ),

        .gm_tx_err                              ( tx_gmii_err[g]    ),
        .m_tx_err                               ( 1'b0  ),
        
        .m_rx_d                                 ( ),
        .m_rx_en                                ( ),

        .gm_rx_err                              ( rx_gmii_err[g]    ),
        .m_rx_err                               ( ),

        .m_rx_col                               ( ),
        .m_rx_crs                               ( )
      );
    end
endgenerate

generate
  for( g = 0; g < PORT_CNT; g++ )
    begin : phy_mapping
      assign tx_gmii_err[g]             = gmii_if[g].tx_err;    
      assign tx_gmii_en[g]              = gmii_if[g].tx_en;     
      assign tx_gmii_data[g]            = gmii_if[g].tx_d;      
      
      assign gmii_if[g].trx.clk125m     = clk_125m_i;
      assign gmii_if[g].trx.rx_clk      = rx_clk[g];
      assign gmii_if[g].trx.tx_clk      = tx_clk[g]; 
      assign gmii_if[g].trx.rx_err      = rx_gmii_err[g];
      assign gmii_if[g].trx.rx_d        = rx_gmii_data[g];
      assign gmii_if[g].trx.rx_dv       = rx_gmii_en[g];
      
      assign trg_if[g].nreset           = xgbe_ctrl_if[g].gbe_nreset;
      
      assign gmii_if[g].trx.rx_speed    = xgbe_ctrl_if[g].rx_port_speed;
      assign gmii_if[g].trx.tx_speed    = xgbe_ctrl_if[g].tx_port_speed;
    end
endgenerate

endmodule
