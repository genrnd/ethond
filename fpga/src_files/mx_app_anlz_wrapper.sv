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
  Вся прикладная логика вынесена в общий файл.
  Его используем в tb и в top.

*/
import feat_anlz::*;


module mx_app_anlz_wrapper #( 
  parameter PORT_CNT = 1 
) (
  input                              main_clk_i              [PORT_CNT-1:0],  
  // 1G PHY
  gmii_phy_if.phy                    gmii_if                 [PORT_CNT-1:0],

  csr_if.slave                       main_reg_csr_if,

  mdio_if.master                     mdio_if                 [PORT_CNT-1:0],
  mx_xgbe_ctrl_if.master             xgbe_ctrl_if            [PORT_CNT-1:0],  
  
  eth_pkt_if.i                       pkt_from_cpu_i          [PORT_CNT-1:0],
  eth_pkt_if.o                       pkt_to_cpu_o            [PORT_CNT-1:0]

);



fpga_id_if               fpga_id_rom_if                  ( main_reg_csr_if.clk );
nic_ctrl_if              nic_if           [PORT_CNT-1:0] ( main_clk_i[PORT_CNT-1:0]       );




genvar z;

generate
  for( z = 0; z < PORT_CNT; z++ )
    begin : anlz

      mx_main_engine 
      me (
          
        .clk_156m25_i                           ( main_clk_i[z]                 ),
        .rst_i                                  ( xgbe_ctrl_if[z].main_engine_arst ),       
        // 1G PHY
        .gmii_if                                ( gmii_if[z]                    ),
        .nic_if                                 ( nic_if[z]                     ),  
        .pkt_to_cpu_o                           ( pkt_to_cpu_o[z]               ),
        .pkt_from_cpu_i                         ( pkt_from_cpu_i[z]             )
      );
    end
endgenerate



  mx_anlz_csr_to_if #( 
    .PORT_CNT                               ( PORT_CNT                         ) 
  ) mx_anlz_csr_to_if(

      // входной интерфейс с настройкой
    .csr_if                                 ( main_reg_csr_if                  ),
      // выходные интерфейсы 
    .fpga_id_rom_if                         ( fpga_id_rom_if                   ),
    .mdio_if                                ( mdio_if                          ),
    .xgbe_ctrl_if                           ( xgbe_ctrl_if                     ),
    .nic_if                                 ( nic_if                           )
  );




fpga_version_rom #( 
  .INIT_FNAME                             ( "fpga_id.mif"                             ) 
) fpga_id_rom(

  .clock                                  ( fpga_id_rom_if.clk_i                      ),
  .address                                ( fpga_id_rom_if.slave.rd_addr              ),
  .q                                      ( fpga_id_rom_if.slave.rd_data              )

);






endmodule
