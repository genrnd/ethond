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
  Модуль преобразования csr_if в интерфейсы управления сетевым стеком. 

*/

import feat_anlz::*;

`include "nic_ctrl_regs.vh"

module nic_ctrl_csr_to_if
#(
   parameter PORT_CNT      = 2,
   parameter PORT_BIT_MASK = 2'b11,
   parameter D_WIDTH       = 16,
   parameter A_WIDTH       = 10
)
(
  

  csr_if.slave                            regfile_if,
  
  nic_ctrl_if.csr                         nic_ctrl_if    [PORT_CNT-1:0] 

);

localparam ONE_PORT_CR_CNT = `NIC_CTRL_CR_CNT;
localparam ONE_PORT_SR_CNT = `NIC_CTRL_SR_CNT;

localparam USED_PORT_CNT   = feat_anlz::port_bit_mask_to_used_ports_cnt( PORT_BIT_MASK ); 
localparam CR_CNT          = ONE_PORT_CR_CNT * USED_PORT_CNT;
localparam SR_CNT          = ONE_PORT_SR_CNT * USED_PORT_CNT;

logic [D_WIDTH-1:0] cregs_w [CR_CNT-1:0];
logic [D_WIDTH-1:0] sregs_w [SR_CNT-1:0];

genvar g;
generate
  for( g = 0; g < PORT_CNT; g++ )
    begin : ifs_decl
      localparam CR_OFFSET    = port_bit_mask_to_offset( g, PORT_BIT_MASK, ONE_PORT_CR_CNT );
      localparam SR_OFFSET    = port_bit_mask_to_offset( g, PORT_BIT_MASK, ONE_PORT_SR_CNT );
      localparam PORT_ENABLE  = PORT_BIT_MASK[g];

      // портовые контрольные и статусные регистры
      logic [D_WIDTH-1:0] p_cregs_w [ONE_PORT_CR_CNT-1:0];
      logic [D_WIDTH-1:0] p_sregs_w [ONE_PORT_SR_CNT-1:0];
      
      always_comb
        begin
          for( int i = 0; i < ONE_PORT_CR_CNT; i++ )
            begin
              p_cregs_w[i] = ( PORT_ENABLE ) ? ( cregs_w[ i + CR_OFFSET ] ): 
                                               ( '0                       );
            end
        end
      
      if( PORT_ENABLE )
        begin
          always_comb
            begin
              for( int i = 0; i < ONE_PORT_SR_CNT; i++ )
                begin
                  sregs_w[ i + SR_OFFSET ] = p_sregs_w[ i ];
                end
            end
        end

      assign nic_ctrl_if[g].host_mac        = { p_cregs_w[ `HOST_MAC_W2_CR ],
                                                p_cregs_w[ `HOST_MAC_W1_CR ],
                                                p_cregs_w[ `HOST_MAC_W0_CR ] };

      assign nic_ctrl_if[g].encaps_vlan     =   p_cregs_w[ `MGMT_VLAN_CR   ][`MGMT_VLAN_CR_VLAN_NUM_B11:
                                                                             `MGMT_VLAN_CR_VLAN_NUM_B0 ];

      assign nic_ctrl_if[g].alt_host_mac    = { p_cregs_w[ `ALT_HOST_MAC_W2_CR ],
                                                p_cregs_w[ `ALT_HOST_MAC_W1_CR ],
                                                p_cregs_w[ `ALT_HOST_MAC_W0_CR ] };

      logic [1:0] nic_mode;

      assign nic_mode = p_cregs_w[ `NIC_MAIN_CR ][ `NIC_MAIN_CR_MODE_B1:
                                                   `NIC_MAIN_CR_MODE_B0 ];

      assign nic_ctrl_if[g].also_use_alt_host_mac = ( nic_mode[1]       );
      assign nic_ctrl_if[g].promisc_mode          = ( nic_mode == 2'b11 );

      assign p_sregs_w[`NIC_CTRL_VER_SR] = `NIC_CTRL_VER; 

    end
endgenerate


regfile_with_be #( 
  .CTRL_CNT                               ( CR_CNT               ), 
  .STAT_CNT                               ( SR_CNT               ), 
  .ADDR_W                                 ( A_WIDTH              ), 
  .DATA_W                                 ( D_WIDTH              ), 
  .SEL_SR_BY_MSB                             ( 0                    )
) nic_regfile (
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
