//////////////////////////////////////////////////////////////////////
////                                                              ////
////  File name "xge_mac.v"                                       ////
////                                                              ////
////  This file is part of the "10GE MAC" project                 ////
////  http://www.opencores.org/cores/xge_mac/                     ////
////                                                              ////
////  Author(s):                                                  ////
////      - A. Tanguay (antanguay@opencores.org)                  ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2008 AUTHORS. All rights reserved.             ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software, you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation, ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`include "defines.vh"
`include "header_structs.sv"

import eth_pkt_lib::*;
import xge_rx::*;

module rx_engine  #( 
  parameter eth_pkt_if_t IF_PROPERTIES = eth_pkt_lib::DEFAULT_PROPERTIES
)
(

  input                            clk_156m25_i,       
  input                            reset_156m25_i,  

  // интерфейс от fetcher'a
  rx_engine_if.engine              pkt_rx_i,
  //Control
  nic_ctrl_if.app                  nic_if,  
  eth_pkt_if.o                     pkt_o
);


pkt_rx_info_t  rxsfifo_wdata;
pkt_rx_info_t  rxsfifo_rdata;
logic          rxsfifo_empty;
logic          rxsfifo_full;
logic [15:0]   rxdfifo_pktlen_dl;

logic ethertype_lb_w;
logic ip_w;
logic oam_w;
logic runt_w;
logic oversize_w;
logic broadcast_w;
logic multicast_w;
logic unicast_w;
logic usercast_w;
logic nic_encaps_w;
logic samemacs_w;
logic telnet_w;
logic et_discover_w;
logic bert_frm_w;
logic ptp_l2_w;
logic ptp_l4_w;
logic xcap_filt_res_w;
logic ssh_w;

logic tcp_w;
logic udp_w;

logic icmp_w;
logic dhcp_w;
logic dns_w;
logic arp_w;

logic        twamp_control_w;
logic [3:0]  twamp_test_flow_num_w;
logic        twamp_reflector_pkt_w;
logic        twamp_sender_pkt_w;




logic [31:0] pkt_rx_time;
logic [31:0] pkt_rx_time_dl;

logic             pkt_rx_avail;  

// структуры в которых хранятся распарсенные поля заголовока пакета
head_l2_s         head_l2; 
head_l25_s        head_l25; 
head_l3_s         head_l3;
head_l4_s         head_l4;

head_l2_s         head_lock_l2; 
head_l25_s        head_lock_l25; 
head_l3_s         head_lock_l3;
head_l4_s         head_lock_l4;

// eop for each level of trafparser
logic head_l2_eop_w;
logic head_l25_eop_w;     
logic head_l3_eop_w;      
logic head_l4_eop_w;

logic head_l2_eop_d1;
logic head_l25_eop_d1;     
logic head_l3_eop_d1;      
logic head_l4_eop_d1;

logic rx_fifo_full;

eth_pkt_if pkt_rx( clk_156m25_i );
eth_pkt_if pkt_rd_fifo( clk_156m25_i );
eth_pkt_if pkt_rd_fifo_status_alligned( clk_156m25_i );

assign pkt_rx.mod       = pkt_rx_i.status[`RXSTATUS_MOD]; 
assign pkt_rx.sop       = pkt_rx_i.status[`RXSTATUS_SOP]; 
assign pkt_rx.eop       = pkt_rx_i.status[`RXSTATUS_EOP];
assign pkt_rx.data      = pkt_rx_i.data;
assign pkt_rx.val       = pkt_rx_i.en;
assign pkt_rx_i.wr_full = rx_fifo_full;

eth_pkt_fifo #( 
  .AWIDTH                                ( 11                    ),
  .SAFE_WORDS                            ( 40                    ),
  .DUAL_CLOCK                            ( 0                     ),

  .SHOWAHEAD                             ( "ON"                  ),
  .LPM_HINT                              ( "RAM_BLOCK_TYPE=M10K" ),

  .USE_WR_ALMOST_FULL_LIKE_WR_PKT_READY  ( 0                     )
) rx_fifo (
 
  .rst_i                                  ( reset_156m25_i    ),
    
  .wr_pkt_i                               ( pkt_rx            ),

  .rd_pkt_o                               ( pkt_rd_fifo       ),
    
  .rd_empty_o                             (                   ),
  .wr_almost_full_o                       ( rx_fifo_full      ),
  .usedw_o                                (                   ),
  .empty_bytes_o                          (                   )

);

// мы должны вычитывать пакет только тогда, когда его статус
// готов в статусной фифошке. поэтому зануляем ready, 
// если pkt_rx_avail в нуле
eth_pkt_if_control_changer #(
  .IF_PROPERTIES                          ( IF_PROPERTIES          ),
  .READY_ACTION                           ( "AND"                  ),
  .VAL_ACTION                             ( "AND"                  )
) pkt_rx_changer (
  .third_party_ready_i                    ( pkt_rx_avail           ),
  .third_party_val_i                      ( pkt_rx_avail           ),

  .pkt_i                                  ( pkt_rd_fifo            ),

  .pkt_o                                  ( pkt_rd_fifo_status_alligned )

);

eth_pkt_if_replace #( 
  .IF_PROPERTIES                          ( IF_PROPERTIES               )
) rx_status_append (
  .next_data_i                            (                             ),
  .next_data_replace_en_i                 ( 1'b0                        ),

  .next_tuser_i                           ( rxsfifo_rdata               ),
  .next_tuser_replace_en_i                ( 1'b1                        ),

  .pkt_i                                  ( pkt_rd_fifo_status_alligned ),
  .pkt_o                                  ( pkt_o                       )
);

//Записываем в статусное фифо по задержанному EOP, чтобы весь статус успел выставиться


logic rxsfifo_wen_dl; //задержанный write enable
delay_sv #(1, 5) rxsfifo_wen_delay (
  .clk ( clk_156m25_i                                  ),
  .rst ( reset_156m25_i                                ),
  .ena ( 1'b1                                          ),
  .d   ( pkt_rx.val && pkt_rx.eop                      ),
  .q   ( rxsfifo_wen_dl                                )
);

//перед записью в статусное фифо нужно задержать
//сигнал, т.к. wen тоже задержанный, а pkt_rx_i.error[`RXSTATUS_ERR_CRC]
//успеет сброситься
logic crcerr_dl; //задержанный crc error

always_ff @( posedge clk_156m25_i or posedge reset_156m25_i )
  if( reset_156m25_i )
    crcerr_dl <= 1'b0;
  else
    if( rxsfifo_wen_dl )  // сбрасываем этот сигнал когда записали в статусную фифо.
      crcerr_dl <= 1'b0;
    else
      if( pkt_rx_i.en && pkt_rx_i.status[`RXSTATUS_EOP]  )
        crcerr_dl <= pkt_rx_i.error[`RXSTATUS_ERR_CRC];

always_ff @( posedge clk_156m25_i or posedge reset_156m25_i )
  if( reset_156m25_i )
    rxdfifo_pktlen_dl <= 16'h0;
  else
    if( rxsfifo_wen_dl )  // сбрасываем этот сигнал когда записали в статусную фифо.
      rxdfifo_pktlen_dl <= 16'h0;
    else
      if( pkt_rx_i.en && pkt_rx_i.status[`RXSTATUS_EOP]  )
        rxdfifo_pktlen_dl <= pkt_rx_i.pkt_len;

always_ff @( posedge clk_156m25_i )
  begin
    if( pkt_rx_i.en && pkt_rx_i.status[`RXSTATUS_SOP] )
      pkt_rx_time <= 'd0;                               //system_timer value
  end

always_ff @( posedge clk_156m25_i )
  begin
    if( pkt_rx_i.en && pkt_rx_i.status[`RXSTATUS_EOP] )
      pkt_rx_time_dl <= pkt_rx_time;
  end
//заполнение для статуса, в зависимости от прибора
  
always_comb
    begin
      rxsfifo_wdata.broadcast            = broadcast_w;
      rxsfifo_wdata.multicast            = multicast_w;
      rxsfifo_wdata.unicast              = unicast_w;
      rxsfifo_wdata.nic_encaps           = nic_encaps_w;
      
      rxsfifo_wdata.usercast             = usercast_w;
      
      rxsfifo_wdata.samemacs             = samemacs_w;
      rxsfifo_wdata.crc_err              = crcerr_dl;
      rxsfifo_wdata.runt                 = runt_w;
      rxsfifo_wdata.oversize             = oversize_w;
      rxsfifo_wdata.ethertype_lb         = ethertype_lb_w;
      rxsfifo_wdata.pkt_size             = rxdfifo_pktlen_dl;
      rxsfifo_wdata.oam                  = oam_w;
      rxsfifo_wdata.arp                  = arp_w;

      rxsfifo_wdata.telnet               = telnet_w;
      rxsfifo_wdata.et_discover          = et_discover_w;
      rxsfifo_wdata.bert                 = bert_frm_w;
      rxsfifo_wdata.ipv4                 = ip_w; //ip datagram received
      rxsfifo_wdata.pkt_rx_time          = pkt_rx_time_dl;
      rxsfifo_wdata.ptp                  = ptp_l2_w | ptp_l4_w;
      rxsfifo_wdata.icmp                 = icmp_w;
      rxsfifo_wdata.dhcp                 = dhcp_w;
      rxsfifo_wdata.dns                  = dns_w;
      
      rxsfifo_wdata.xcap                 = xcap_filt_res_w;

      rxsfifo_wdata.twamp_control        = twamp_control_w;
      rxsfifo_wdata.twamp_sender         = twamp_sender_pkt_w;
      rxsfifo_wdata.twamp_reflector      = twamp_reflector_pkt_w;
      rxsfifo_wdata.twamp_test_flow_num  = twamp_test_flow_num_w;
      


      rxsfifo_wdata.vlan_cnt             = head_lock_l2.vlan_cnt;
      rxsfifo_wdata.mpls_cnt             = head_lock_l25.mpls_cnt;

      rxsfifo_wdata.ssh                  = ssh_w;

      rxsfifo_wdata.tcp                  = tcp_w;
      rxsfifo_wdata.udp                  = udp_w;
    end

logic rxsfifo_rd_req;

assign rxsfifo_rd_req = pkt_o.val && pkt_o.ready && pkt_o.eop;

rx_stat_fifo #( 
  .DWIDTH       ( $bits( rxsfifo_wdata )         ),
  .WORDS        ( 256                            )
) rx_stat_fifo (
  .clock        ( clk_156m25_i                   ),
  .aclr         ( reset_156m25_i                 ),

  .empty_o      ( rxsfifo_empty                  ),
  .full         ( rxsfifo_full                   ),
  .data         ( rxsfifo_wdata                  ),
  .rdreq        ( rxsfifo_rd_req                 ),
  .wrreq        ( rxsfifo_wen_dl                 ),
  .q            ( rxsfifo_rdata                  )
);


//There is hole packet in rx data fifo
assign pkt_rx_avail = ~rxsfifo_empty;

trafclasser #( 
  .TWAMP_CLASSER_EN                     ( 0                            ) 
) trafclasser(
.clk_i                                  ( clk_156m25_i                 ),
.rst_i                                  ( reset_156m25_i               ),
.clken_i                                ( 1'b1                         ),
 
.crc_err_i                              ( crcerr_dl                    ),
//data inputs
.macs_i                                 ( head_lock_l2.macs            ),
.macs_en_i                              ( head_lock_l2.macs_en         ),
.macd_i                                 ( head_lock_l2.macd            ),
.macd_en_i                              ( head_lock_l2.macd_en         ),
.ethtype_i                              ( head_lock_l2.ethtype         ),
.ethtype_en_i                           ( head_lock_l2.ethtype_en      ),

.vlan0_vid_i                            ( head_lock_l2.vlan0_vid       ),
.vlan0_vid_en_i                         ( head_lock_l2.vlan0_vid_en    ),
.vlan1_vid_i                            ( head_lock_l2.vlan1_vid       ),
.vlan1_vid_en_i                         ( head_lock_l2.vlan1_vid_en    ),
.vlan2_vid_i                            ( head_lock_l2.vlan2_vid       ),
.vlan2_vid_en_i                         ( head_lock_l2.vlan2_vid_en    ),

.mpls0_i                                ( head_lock_l25.mpls0          ),
.mpls0_en_i                             ( head_lock_l25.mpls0_en       ),
                                                     
.mpls1_i                                ( head_lock_l25.mpls1          ),
.mpls1_en_i                             ( head_lock_l25.mpls1_en       ),
                                                     
.mpls2_i                                ( head_lock_l25.mpls2          ),
.mpls2_en_i                             ( head_lock_l25.mpls2_en       ),

.frm_len_i                              ( rxdfifo_pktlen_dl           ),

.ip_prot_i                              ( head_lock_l3.ip_prot         ),
.ip_prot_en_i                           ( head_lock_l3.ip_prot_en      ),

.ip_tos_i                               ( head_lock_l3.ip_tos         ),
.ip_tos_en_i                            ( head_lock_l3.ip_tos_en      ),

.ip_src_i                               ( head_lock_l3.ip_src         ),
.ip_src_en_i                            ( head_lock_l3.ip_src_en       ),

.ip_dst_i                               ( head_lock_l3.ip_dst          ),
.ip_dst_en_i                            ( head_lock_l3.ip_dst_en       ),

.port_src_i                             ( head_lock_l4.port_src        ),
.port_src_en_i                          ( head_lock_l4.port_src_en     ),

.port_dst_i                             ( head_lock_l4.port_dst        ),
.port_dst_en_i                          ( head_lock_l4.port_dst_en     ),

//Control

.nic_if                                 ( nic_if            ),

//.frm_len_min_i                          ( `FRMSIZE_MIN      ),
//.frm_len_max_i                          ( `FRMSIZE_MAX      ),

// вообще, это должно зависеть от того, для какого проекта используется
// rx_engine..., т.к. для 10G это может быть 64000
.frm_len_min_i                          ( 16'd64            ),
.frm_len_max_i                          ( 16'd9600          ),





//Classification result outputs
.ip_o                                   ( ip_w              ),
.oam_o                                  ( oam_w             ),
.ethertype_lb_o                         ( ethertype_lb_w    ),
.oversize_o                             ( oversize_w        ),
.runt_o                                 ( runt_w            ),
.broadcast_o                            ( broadcast_w       ),
.multicast_o                            ( multicast_w       ),
.unicast_o                              ( unicast_w         ),
.usercast_o                             ( usercast_w        ),
.nic_encaps_o                           ( nic_encaps_w      ),
.samemacs_o                             ( samemacs_w        ),
.arp_o                                  ( arp_w             ),

.tcp_o                                  ( tcp_w             ),
.udp_o                                  ( udp_w             ),

.telnet_o                               ( telnet_w          ),
.ssh_o                                  ( ssh_w             ),
.et_discover_o                          ( et_discover_w     ),
.bert_frm_o                             ( bert_frm_w        ),  
.ptp_l2_o                               ( ptp_l2_w          ),
.ptp_l4_o                               ( ptp_l4_w          ),

.icmp_o                                 ( icmp_w            ),
.dhcp_o                                 ( dhcp_w            ),
.dns_o                                  ( dns_w             ),

.twamp_control_o                        ( twamp_control_w       ),

.twamp_test_flow_num_o                  ( twamp_test_flow_num_w ),
.twamp_reflector_pkt_o                  ( twamp_reflector_pkt_w ),
.twamp_sender_pkt_o                     ( twamp_sender_pkt_w    ),

.xcap_filt_res_o                        ( xcap_filt_res_w       )
);


//Находит нужные поля в пакете
trafparser trafparser(
.clk_i                                  ( clk_156m25_i      ),
.rst_i                                  ( reset_156m25_i    ),
.en_i                                   ( 1'b1              ),
  //Packet rx interface
.pkt_sop_i                              ( pkt_rx_i.status[`RXSTATUS_SOP] ),
.pkt_eop_i                              ( pkt_rx_i.status[`RXSTATUS_EOP] ),
.pkt_en_i                               ( pkt_rx_i.en                    ),
.pkt_data_i                             ( pkt_rx_i.data                  ),
.pkt_mod_i                              ( pkt_rx_i.status[`RXSTATUS_MOD] ),

// eop for each level
.pkt_l2_eop_o                           ( head_l2_eop_w               ),
.pkt_l25_eop_o                          ( head_l25_eop_w              ),
.pkt_l3_eop_o                           ( head_l3_eop_w               ),
.pkt_l4_eop_o                           ( head_l4_eop_w               ),

 //output status
.macd_o                                 ( head_l2.macd                ),
.macs_o                                 ( head_l2.macs                ),
.macd_en_o                              ( head_l2.macd_en             ),
.macs_en_o                              ( head_l2.macs_en             ),
.ethtype_o                              ( head_l2.ethtype             ),
.ethtype_en_o                           ( head_l2.ethtype_en          ),
.vlan0_vid_o                            ( head_l2.vlan0_vid           ),
.vlan0_vid_en_o                         ( head_l2.vlan0_vid_en        ),
.vlan1_vid_o                            ( head_l2.vlan1_vid           ),
.vlan1_vid_en_o                         ( head_l2.vlan1_vid_en        ),
.vlan2_vid_o                            ( head_l2.vlan2_vid           ),
.vlan2_vid_en_o                         ( head_l2.vlan2_vid_en        ),

.vlan_cnt_o                             ( head_l2.vlan_cnt            ),

.mpls0_o                                ( head_l25.mpls0              ),
.mpls0_en_o                             ( head_l25.mpls0_en           ),
          
.mpls1_o                                ( head_l25.mpls1              ),
.mpls1_en_o                             ( head_l25.mpls1_en           ),
          
.mpls2_o                                ( head_l25.mpls2              ),
.mpls2_en_o                             ( head_l25.mpls2_en           ),

.mpls_cnt_o                             ( head_l25.mpls_cnt           ),

  //ip level outputs
.ip_src_o                               ( head_l3.ip_src               ),
.ip_src_en_o                            ( head_l3.ip_src_en            ),

.ip_dst_o                               ( head_l3.ip_dst               ),
.ip_dst_en_o                            ( head_l3.ip_dst_en            ),

.ipv6_src_o                             ( head_l3.ipv6_src             ),
.ipv6_src_en_o                          ( head_l3.ipv6_src_en          ),

.ipv6_dst_o                             ( head_l3.ipv6_dst             ),
.ipv6_dst_en_o                          ( head_l3.ipv6_dst_en          ),

.ip_prot_o                              ( head_l3.ip_prot              ),
.ip_prot_en_o                           ( head_l3.ip_prot_en           ),

.port_src_o                             ( head_l4.port_src             ),
.port_src_en_o                          ( head_l4.port_src_en          ),

.port_dst_o                             ( head_l4.port_dst             ),
.port_dst_en_o                          ( head_l4.port_dst_en          ),

.ip_tos_o                               ( head_l3.ip_tos               ),
.ip_tos_en_o                            ( head_l3.ip_tos_en            ),

.ip_ident_o                             ( head_l3.ip_ident             ),
.ip_ident_en_o                          ( head_l3.ip_ident_en          ),

.ip_flags_offset_o                      ( head_l3.ip_flags_offset      ),
.ip_flags_offset_en_o                   ( head_l3.ip_flags_offset_en   ),
  
.tcp_flags_o                            ( head_l4.tcp_flags            ),
.tcp_flags_en_o                         ( head_l4.tcp_flags_en         )
);

always_ff @( posedge clk_156m25_i or posedge reset_156m25_i )
  if( reset_156m25_i )
    begin
      head_l2_eop_d1  <= 1'b0;
      head_l25_eop_d1 <= 1'b0;
      head_l3_eop_d1  <= 1'b0;
      head_l4_eop_d1  <= 1'b0;
    end
  else
    begin
      head_l2_eop_d1  <= head_l2_eop_w;
      head_l25_eop_d1 <= head_l25_eop_w;
      head_l3_eop_d1  <= head_l3_eop_w;
      head_l4_eop_d1  <= head_l4_eop_w;
    end


always_ff @( posedge clk_156m25_i or posedge reset_156m25_i)
  begin
    if( reset_156m25_i )
      head_lock_l2 <= '0;
    else
      if( head_l2_eop_w && ~head_l2_eop_d1 )
        head_lock_l2 <= head_l2;
  end

always_ff @( posedge clk_156m25_i )
  begin
    if( reset_156m25_i )
      head_lock_l25 <= '0;
    else
      if( head_l25_eop_w && ~head_l25_eop_d1 )
        head_lock_l25 <= head_l25;
  end

always_ff @( posedge clk_156m25_i )
  begin
    if( reset_156m25_i )
      head_lock_l3 <= '0;
    else
      if( head_l3_eop_w && ~head_l3_eop_d1 )
        head_lock_l3 <= head_l3;
  end

always_ff @( posedge clk_156m25_i )
  begin
    if( reset_156m25_i )
      head_lock_l4 <= '0;
    else
      if( head_l4_eop_w && ~head_l4_eop_d1 )
        head_lock_l4 <= head_l4;
  end




endmodule

