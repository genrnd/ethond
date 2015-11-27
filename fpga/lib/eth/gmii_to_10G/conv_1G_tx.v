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

module conv_1G_tx #( 
  parameter REDUCED_FIFO = 0 
)
(
  input                tx_clk_i,  
  input                tx_clk_en_i, 
  input                rst_tx_clk_i,

  input                clk_sys_i,

  output logic   [7:0] TxD,
  output logic         TxEn,   

  //XFACE
  output logic         tx_fifo_full_o,
  input         [63:0] pkt_tx_data_i, 
  input         [2:0]  pkt_tx_mod_i,
  input                pkt_tx_sop_i,
  input                pkt_tx_eop_i,
  input                pkt_tx_val_i
);

// CRC_gen Interface 
logic         CRC_init;  
logic [7:0]   Frame_data;
logic         Data_en;   
logic         CRC_rd;              
logic         CRC_end;             
logic   [7:0] CRC_out;             

conv_1G_tx_ctrl #( 
  .REDUCED_FIFO                           ( REDUCED_FIFO      ) 
) conv_1G_tx_ctrl(

  .clk_i                                  ( tx_clk_i          ),
  .clk_en_i                               ( tx_clk_en_i       ),
  .rst_i                                  ( rst_tx_clk_i      ),

  .Clk_user                               ( clk_sys_i         ),

  // PHY interface
  .TxD                                    ( TxD               ),
  .TxEn                                   ( TxEn              ),

  // CRC_gen Interface 
  .CRC_init                               ( CRC_init          ),
  .Frame_data                             ( Frame_data        ),
  .Data_en                                ( Data_en           ),
  .CRC_rd                                 ( CRC_rd            ),
  .CRC_end                                ( CRC_end           ),
  .CRC_out                                ( CRC_out           ),

  .pkt_tx_data_i                          ( pkt_tx_data_i     ),
  .pkt_tx_mod_i                           ( pkt_tx_mod_i      ),
  .pkt_tx_sop_i                           ( pkt_tx_sop_i      ),
  .pkt_tx_eop_i                           ( pkt_tx_eop_i      ),
  .pkt_tx_val_i                           ( pkt_tx_val_i      ),
  .tx_fifo_full_o                         ( tx_fifo_full_o    )
);

CRC_gen CRC_gen (
  .Clk                                    ( tx_clk_i          ),
  .clk_en_i                               ( tx_clk_en_i       ),
  .Reset                                  ( rst_tx_clk_i      ),

  .Init                                   ( CRC_init          ),
  .Frame_data                             ( Frame_data        ),
  .Data_en                                ( Data_en           ),
  .CRC_rd                                 ( CRC_rd            ),
  .CRC_end                                ( CRC_end           ),
  .CRC_out                                ( CRC_out           )
);

endmodule
