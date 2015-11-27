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
  Модуль, который содержит в себе все остальные *_csr_to_if модули,
  которые преобразуют интерфейсы csr в используемые интерфейсы в проекте MX.
  
*/

`define BASE_ADDR { 10'd59, 10'd41, 10'd9, 10'd0 }
`define FEAT_CNT 3
`define REGFILE_MX_FPGA_ID 0
`define REGFILE_MX_PHY 1
`define REGFILE_NIC_CTRL 2



module mx_anlz_csr_to_if
#( 
  parameter PORT_CNT = 2 
)
(  
  // входной интерфейс с настройкой
  csr_if.slave                   csr_if,
  // выходные интерфейсы 
  fpga_id_if.master              fpga_id_rom_if, 
  mdio_if.master                 mdio_if             [PORT_CNT-1:0],
  mx_xgbe_ctrl_if.master         xgbe_ctrl_if        [PORT_CNT-1:0],
  nic_ctrl_if.csr                nic_if              [PORT_CNT-1:0]
);

// сколько всего регфайлов
localparam REGFILE_CNT = `FEAT_CNT;
localparam REG_WIDTH   = 16;
localparam REG_ADDR_W  = 10;

logic [REGFILE_CNT:0][REG_ADDR_W-1:0] base_addr_w;

assign base_addr_w = `BASE_ADDR;



csr_if 
#( 
  .A_WIDTH                        ( REG_ADDR_W  ),
  .D_WIDTH                        ( REG_WIDTH   ),
  .BE_WIDTH                       ( REG_WIDTH/8 )
) regfile_if[REGFILE_CNT-1:0] ( 

  .clk                            ( csr_if.clk  )
);

// декодер адреса - из одного csr_if делаем "много" 
csr_addr_decoder
#( 
  
  .SLAVE_CNT                              ( REGFILE_CNT       ), 
  .ADDR_W                                 ( REG_ADDR_W        ),
  .BE_W                                   ( REG_WIDTH/8       )

) mx_addr_decoder(

  .base_addr_i                            ( base_addr_w       ),

  .master_csr_if                          ( csr_if            ),
  .slave_csr_if                           ( regfile_if        )

);

mx_fpga_id_to_if mx_fpga_id_to_if(
  
  .regfile_if                             ( regfile_if[`REGFILE_MX_FPGA_ID]    ),    
  .fpga_id_rom_if                         ( fpga_id_rom_if                     )

);

// управление физикой ( 1G интерфейс )
  mx_phy_csr_to_if #(
     .PORT_CNT                              ( PORT_CNT                        ),
     .PORT_BIT_MASK                         ( 2'b11                           ),
     .D_WIDTH                               ( REG_WIDTH                       ),
     .A_WIDTH                               ( REG_ADDR_W                      )
  ) mx_phy_csr_to_if(

    .regfile_if                             ( regfile_if[`REGFILE_MX_PHY]     ),      
    .mdio_if                                ( mdio_if                         ),
    .xgbe_ctrl_if                           ( xgbe_ctrl_if                    )

  );


  nic_ctrl_csr_to_if
  #(
     .PORT_CNT                              ( PORT_CNT                         ),
     .PORT_BIT_MASK                         ( 2'b11                            ),
     .D_WIDTH                               ( REG_WIDTH                        ),
     .A_WIDTH                               ( REG_ADDR_W                       )
  ) nic_ctrl_csr_to_if(

    .regfile_if                             ( regfile_if[`REGFILE_NIC_CTRL]    ),      
    .nic_ctrl_if                            ( nic_if                           )

  );





endmodule
