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
  Модуль преобразования csr_if в интерфейс чтения статистики по интерфейсам и пр.

*/

import feat_anlz::*;

`include "mx_phy_regs.vh"

module mx_phy_csr_to_if
#(
   parameter PORT_CNT      = 2,
   parameter PORT_BIT_MASK = 2'b11,
   parameter D_WIDTH       = 16,
   parameter A_WIDTH       = 10
)
(
  

  csr_if.slave                   regfile_if,
  
  mdio_if.master                 mdio_if      [PORT_CNT-1:0],
  mx_xgbe_ctrl_if.master         xgbe_ctrl_if [PORT_CNT-1:0]

);


localparam ONE_PORT_CR_CNT = `MX_PHY_CR_CNT;
localparam ONE_PORT_SR_CNT = `MX_PHY_SR_CNT;

localparam USED_PORT_CNT   = feat_anlz::port_bit_mask_to_used_ports_cnt( PORT_BIT_MASK ); 
localparam CR_CNT          = ONE_PORT_CR_CNT * USED_PORT_CNT;
localparam SR_CNT          = ONE_PORT_SR_CNT * USED_PORT_CNT;

logic [D_WIDTH-1:0] cregs_w [CR_CNT-1:0];
logic [D_WIDTH-1:0] sregs_w [SR_CNT-1:0];

genvar i;
generate
  for( i = 0; i < PORT_CNT; i++ )
    begin : port
      
      localparam CR_OFFSET    = port_bit_mask_to_offset( i, PORT_BIT_MASK, ONE_PORT_CR_CNT );
      localparam SR_OFFSET    = port_bit_mask_to_offset( i, PORT_BIT_MASK, ONE_PORT_SR_CNT );
      localparam PORT_ENABLE  = PORT_BIT_MASK[i];

      // портовые контрольные и статусные регистры
      logic [D_WIDTH-1:0] p_cregs_w [ONE_PORT_CR_CNT-1:0];
      logic [D_WIDTH-1:0] p_sregs_w [ONE_PORT_SR_CNT-1:0];
      
      
      always_comb
        begin
          for( int j = 0; j < ONE_PORT_CR_CNT; j++ )
            begin
              p_cregs_w[j] = ( PORT_ENABLE ) ? ( cregs_w[ j + CR_OFFSET ] ): 
                                               ( '0                       );
            end
        end

      if( PORT_ENABLE ) 
        begin

          always_comb
            begin
              for( int j = 0; j < ONE_PORT_SR_CNT; j++ )
                begin
                  sregs_w[ j + SR_OFFSET ] = p_sregs_w[ j ];
                end
            end

        end


      // ********** MDIO **********
      assign mdio_if[i].rst                     = p_cregs_w[ `MDIO_CR       ][ `MDIO_CR_RST           ]; 
      assign mdio_if[i].run                     = p_cregs_w[ `MDIO_CR       ][ `MDIO_CR_RUN           ]; 
      assign mdio_if[i].cop                     = p_cregs_w[ `MDIO_CR       ][ `MDIO_CR_COP_B1:
                                                                              `MDIO_CR_COP_B0        ]; 
      assign mdio_if[i].fw_loading              = p_cregs_w[ `MDIO_CR       ][ `MDIO_CR_FW            ]; 

      assign mdio_if[i].divider                 = p_cregs_w[ `MDIODIV_CR    ][ `MDIODIV_CR_DIV_B5:
                                                                               `MDIODIV_CR_DIV_B0     ];

      assign mdio_if[i].phy_addr                = p_cregs_w[ `MDIOPHYAD_CR  ][ `MDIOPHYAD_CR_PHYAD_B4:
                                                                               `MDIOPHYAD_CR_PHYAD_B0 ];
                                               
      assign mdio_if[i].dev_addr                = p_cregs_w[ `MDIODEVAD_CR  ][ `MDIODEVAD_CR_DEVAD_B4:
                                                                               `MDIODEVAD_CR_DEVAD_B0 ]; 

      assign mdio_if[i].wr_data                 = p_cregs_w[ `MDIODATALO_CR ]; 

      assign mdio_if[i].fw_wr_data_w0           = p_cregs_w[ `VSC_FW_W0_CR  ]; 
      assign mdio_if[i].fw_wr_data_w1           = p_cregs_w[ `VSC_FW_W1_CR  ];

      assign mdio_if[i].fw_rst                  = p_cregs_w[ `VSC_FW_MN_CR  ][ `VSC_FW_MN_CR_RST ];
      assign mdio_if[i].fw_run                  = p_cregs_w[ `VSC_FW_MN_CR  ][ `VSC_FW_MN_CR_RUN ];
        
      assign p_sregs_w[ `MDIODATALO_SR ]                = mdio_if[i].rd_data;
      assign p_sregs_w[ `MDIO_SR ][ `MDIO_SR_DATAVAL ]  = mdio_if[i].rd_data_val;
      assign p_sregs_w[ `MDIO_SR ][ `MDIO_SR_BUSY    ]  = mdio_if[i].busy;

      assign p_sregs_w[ `MDIO_SR ][ `MDIO_SR_FW_BUSY ]  = mdio_if[i].fw_busy;

      // ********** xgbe status/control **********

      // выключение передачи в SFP
      assign xgbe_ctrl_if[i].tx_disable = p_cregs_w[`TRX_CR][`TRX_CR_EX_TX_DIS];

      // отсутствие модуля
      assign p_sregs_w[`TRX_SR][`TRX_SR_EX_ABS]   = xgbe_ctrl_if[i].mod_abs;

      // отсутствие сигнала
      assign p_sregs_w[`TRX_SR][`TRX_SR_EX_LOS]   = xgbe_ctrl_if[i].rx_los;

      // сломался передатчик SFP+
      assign p_sregs_w[`TRX_SR][`TRX_SR_EX_TXFLT] = xgbe_ctrl_if[i].tx_fault;

      // loss of optical power
      assign p_sregs_w[`TRX_SR][`TRX_SR_EX_LOPC]  = xgbe_ctrl_if[i].lopc;

      //сигналы 10G трансиверов
      assign xgbe_ctrl_if[i].xge_nreset         = p_cregs_w[ `TRX_CR        ][ `TRX_CR_EX_NRST   ];

      //сигналы 1G трансиверов
      assign xgbe_ctrl_if[i].gbe_nreset         = p_cregs_w[ `TRX_CR        ][ `TRX_CR_EG_NRST   ];

      assign xgbe_ctrl_if[i].gbe_coma           = p_cregs_w[ `TRX_CR        ][ `TRX_CR_EG_COMA   ];

      // различные леды
      assign xgbe_ctrl_if[i].alrm_led           = p_cregs_w[ `LED_CR        ][ `LED_CR_ALRM      ];

      assign xgbe_ctrl_if[i].rx_led             = p_cregs_w[ `LED_CR        ][ `LED_CR_RX        ];    

      assign xgbe_ctrl_if[i].test_led           = p_cregs_w[ `LED_CR        ][ `LED_CR_TEST      ];

      assign xgbe_ctrl_if[i].rx_port_speed      = p_cregs_w[ `PORT_SPEED_CR ][ `PORT_SPEED_CR_RX_SPEED_B3:
                                                                               `PORT_SPEED_CR_RX_SPEED_B0 ];

      assign xgbe_ctrl_if[i].tx_port_speed      = p_cregs_w[ `PORT_SPEED_CR ][ `PORT_SPEED_CR_TX_SPEED_B3:
                                                                               `PORT_SPEED_CR_TX_SPEED_B0 ];


      sedge_sel_sv me_arst_stb(
        //.Clk                                 ( clk_25m_i                                        ),
        // FIXME: пока хз на каком клоке надо это всё делать
        .Clk                                 ( regfile_if.clk                                   ),
        .ain                                 ( p_cregs_w[`RST_ENGINE_CR][`RST_ENGINE_CR_MAIN_RST] ),
        .edg                                 ( xgbe_ctrl_if[i].main_engine_arst                    )
      );

      assign xgbe_ctrl_if[i].tb_gen_pkt_en = p_cregs_w[`RST_ENGINE_CR][`RST_ENGINE_CR_TB_GEN_PKT_EN];

      assign p_sregs_w[`MX_PHY_VER_SR]    = `MX_PHY_VER;
    end
endgenerate


regfile_with_be #( 
  .CTRL_CNT                               ( CR_CNT               ), 
  .STAT_CNT                               ( SR_CNT               ), 
  .ADDR_W                                 ( A_WIDTH              ), 
  .DATA_W                                 ( D_WIDTH              ), 
  .SEL_SR_BY_MSB                          ( 0                    )
) phy_regfile (
  .clk_i                                  ( regfile_if.clk       ),
  .rst_i                                  ( 1'b0                 ),

  .data_i                                 ( regfile_if.wr_data   ),
  .wren_i                                 ( regfile_if.wr_en     ),
  .addr_i                                 ( regfile_if.addr      ),
  .be_i                                   ( regfile_if.be        ),
  .sreg_i                                 ( sregs_w              ),
  .data_o                                 ( regfile_if.rd_data   ),
  .creg_o                                 ( cregs_w              )
); 

endmodule
