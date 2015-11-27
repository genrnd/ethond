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

module conv_1G_rx(
  input                 rx_clk_i,  
  input                 rx_clk_en_i, 

  input                 rst_rx_clk_i,

  input                 clk_sys_i,
  
  input        [7:0]    rx_d_i,
  input                 rx_dv_i,
  input                 rx_err_i,

  // XFACE
  input                 tr_en_fifo_full_i,
  output logic [63:0]   pkt_rx_data_o,
  output logic [7:0]    pkt_rx_status_o,
  output logic [2:0]    pkt_rx_error_o,
  output logic [15:0]   pkt_rx_len_o,
  output logic          pkt_rx_val_o
);

// fifo interface
logic [7:0] fifo_data;
logic       fifo_data_en;
logic       fifo_data_err;
logic       fifo_data_end;
logic       fifo_full;

//crc interface
logic       crc_err_frm_w;

logic       frame_crc_err;

gbe_rx_mac_ctrl_simple #(
  .RX_IFG_SET                             ( 12                ),
  .RX_MIN_LEN                             ( 64                ),
  .RX_MAX_LEN                             ( 9600              )
) mac_ctrl (
  
  .clk_i                                  ( rx_clk_i          ),
  .clk_en_i                               ( rx_clk_en_i       ),

  .rst_i                                  ( rst_rx_clk_i      ),
    
  .rx_d_i                                 ( rx_d_i            ),
  .rx_dv_i                                ( rx_dv_i           ),
  .rx_err_i                               ( rx_err_i          ),
    
  .fifo_data_o                            ( fifo_data         ),
  .fifo_data_en_o                         ( fifo_data_en      ),
  .fifo_data_err_o                        ( fifo_data_err     ),
  .fifo_data_end_o                        ( fifo_data_end     ),
  .fifo_full_i                            ( fifo_full         ),

  .crc_err_o                              ( crc_err_frm_w     )

);

logic        pkt_avail;
logic        fifo_rd_req;

logic [63:0] pkt_fifo_data_w;
logic        pkt_fifo_sop_w;
logic        pkt_fifo_eop_w;
logic [2:0]  pkt_fifo_mod_w;

// Переводим из 8 битного интерфейса в 64 битный, записываем
// в fifo с sop, eop, mod
conv_1G_rx_fifo conv_1G_rx_fifo(

  .clk_mac_i                              ( rx_clk_i          ),
  .clk_mac_en_i                           ( rx_clk_en_i       ),
  .rst_i                                  ( rst_rx_clk_i      ),

  .clk_sys_i                              ( clk_sys_i         ),

  .fifo_wr_data_i                         ( fifo_data         ),
  .fifo_wr_data_en_i                      ( fifo_data_en      ),
  .fifo_wr_data_err_i                     ( fifo_data_err     ),
  .fifo_wr_data_end_i                     ( fifo_data_end     ),
  .frame_crc_err_i                        ( crc_err_frm_w     ),
  .fifo_full_o                            ( fifo_full         ),

  .fifo_rd_req_i                          ( fifo_rd_req       ),
  .frame_crc_err_o                        ( frame_crc_err     ),

  .pkt_data_o                             ( pkt_fifo_data_w   ),
  .pkt_sop_o                              ( pkt_fifo_sop_w    ),
  .pkt_eop_o                              ( pkt_fifo_eop_w    ),
  .pkt_mod_o                              ( pkt_fifo_mod_w    ),

  .pkt_avail_o                            ( pkt_avail         )

);

conv_1G_rx_arb conv_1G_rx_arb(

  .clk_i                                  ( clk_sys_i            ),
  // FIXME: не можем использовать rst_rx_clk_i, т.к. клоковый домен другой
  // (системный) 
  .rst_i                                  ( 1'b0                 ), 

  .pkt_avail_i                            ( pkt_avail            ),

  .pkt_data_i                             ( pkt_fifo_data_w      ),
  .pkt_sop_i                              ( pkt_fifo_sop_w       ),
  .pkt_eop_i                              ( pkt_fifo_eop_w       ),
  .pkt_mod_i                              ( pkt_fifo_mod_w       ),
  .frame_crc_err_i                        ( frame_crc_err        ),

  .fifo_rd_req_o                          ( fifo_rd_req          ),

  .tr_en_fifo_full_i                      ( tr_en_fifo_full_i    ),
  .pkt_fifo_data_o                        ( pkt_rx_data_o        ),
  .pkt_fifo_status_o                      ( pkt_rx_status_o      ),
  .pkt_fifo_error_o                       ( pkt_rx_error_o       ),
  .pkt_len_o                              ( pkt_rx_len_o         ),
  .pkt_fifo_val_o                         ( pkt_rx_val_o         )
);

endmodule
