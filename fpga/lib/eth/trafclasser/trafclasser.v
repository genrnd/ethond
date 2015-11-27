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
Module: trafclasser
Purpose: classification of packets by predetermined field values on different 
         layers:  
*/



module trafclasser #( 
  parameter TWAMP_CLASSER_EN = 1 
)
(
  input          clk_i,
  input          rst_i,
  input          clken_i,
  
//data inputs
  input          crc_err_i,
  input [47:0]   macs_i,    //mac source address
  input          macs_en_i, //mac source enable

  input [47:0]   macd_i,    //mac dest address
  input          macd_en_i, //mac dest enable

  input [15:0]   ethtype_i,       //ethertype field
  input          ethtype_en_i,    //enable для ethtype_o

  input [15:0]   vlan0_vid_i,     //vlan0 vlan ID (+ PCP, CFI bits)
  input          vlan0_vid_en_i,  //enable for vlan0_vid_o

  input [15:0]   vlan1_vid_i,     //vlan1 vlan ID (+ PCP, CFI bits)
  input          vlan1_vid_en_i,  //enable for vlan1_vid_o

  input [15:0]   vlan2_vid_i,     //vlan2 vlan ID (+ PCP, CFI bits)
  input          vlan2_vid_en_i,  //enable for vlan2_vid_o

  input [31:0]   mpls0_i,  
  input          mpls0_en_i,

  input [31:0]   mpls1_i,  
  input          mpls1_en_i,

  input [31:0]   mpls2_i,  
  input          mpls2_en_i,
  
  input [15:0]   frm_len_i,       //rx frame length

  //layer 3 & 4 inputs

  input [7:0]    ip_prot_i,
  input          ip_prot_en_i,

  input [7:0]    ip_tos_i,
  input          ip_tos_en_i,
  
  input [31:0]   ip_src_i,
  input          ip_src_en_i,
  
  input [31:0]   ip_dst_i,
  input          ip_dst_en_i,

  input [15:0]   port_src_i,
  input          port_src_en_i,

  input [15:0]   port_dst_i,
  input          port_dst_en_i,

//Control
  
  nic_ctrl_if.app           nic_if,

  input [15:0]   frm_len_min_i, //minimum allowed frame size
  input [15:0]   frm_len_max_i, //maximum allowed frame size




//Classification result outputs
  output             ip_o,           // ip frame
  output             oam_o,          // oam frame
  output             ethertype_lb_o, // keep alive frame (ethertype 0x9000)
  output             oversize_o,     // oversize frame(>maximum allowed)
  output             runt_o,         // runt frame(<minimum allowed)
  output logic       broadcast_o,    // broadcast detected
  output logic       multicast_o,    // muticast detected
  output logic       unicast_o,      // unicast detected
  output logic       usercast_o,     // our mac detected
  output logic       nic_encaps_o,   // packet FROM CPU: have encaps vlan
  output logic       samemacs_o,     // same mac addresses detected
  output logic       arp_o,          // ARP-message detected
  
  output logic       tcp_o,
  output logic       udp_o,

  output logic       telnet_o,       // telnet frame
  output logic       ssh_o,
  output logic       et_discover_o,  // et discover
  output logic       bert_frm_o,

  output logic       icmp_o,
  output logic       dhcp_o,
  output logic       dns_o,
  
  output logic       ptp_l2_o,
  output logic       ptp_l4_o,

  // TWAMP flags
  output logic       twamp_control_o,

  output logic [3:0] twamp_test_flow_num_o,
  output logic       twamp_reflector_pkt_o,
  output logic       twamp_sender_pkt_o,

  output logic       xcap_filt_res_o

);

l2_classer l2_classer(
.clk_i                                  ( clk_i             ),
.rst_i                                  ( rst_i             ),
.clken_i                                ( clken_i           ),

//data inputs
.macs_i                                 ( macs_i            ),
.macs_en_i                              ( macs_en_i         ),

.macd_i                                 ( macd_i            ),
.macd_en_i                              ( macd_en_i         ),

.ethtype_i                              ( ethtype_i         ),
.ethtype_en_i                           ( ethtype_en_i      ),

.vlan0_vid_i                            ( vlan0_vid_i       ),
.vlan0_vid_en_i                         ( vlan0_vid_en_i    ),

.vlan1_vid_i                            ( vlan1_vid_i       ),
.vlan1_vid_en_i                         ( vlan1_vid_en_i    ),

.vlan2_vid_i                            ( vlan2_vid_i       ),
.vlan2_vid_en_i                         ( vlan2_vid_en_i    ),

.frm_len_i                              ( frm_len_i         ),

//control
.nic_if                                 ( nic_if            ),

.frm_len_min_i                          ( frm_len_min_i     ),
.frm_len_max_i                          ( frm_len_max_i     ),
//Classification result outputs
.ip_o                                   ( ip_o              ),
.oam_o                                  ( oam_o             ),
.ethertype_lb_o                         ( ethertype_lb_o    ),
.oversize_o                             ( oversize_o        ),
.runt_o                                 ( runt_o            ),
.broadcast_o                            ( broadcast_o       ),
.multicast_o                            ( multicast_o       ),
.unicast_o                              ( unicast_o         ),
.usercast_o                             ( usercast_o        ),
.nic_encaps_o                           ( nic_encaps_o      ),
.samemacs_o                             ( samemacs_o        ),
.ptp_l2_o                               ( ptp_l2_o          ),
.arp_o                                  ( arp_o             )
);

tcp_udp_classer tcp_udp_classer(
  .clk_i                                  ( clk_i             ),
  .rst_i                                  ( rst_i             ),
  .clken_i                                ( clken_i           ),

  //data inputs
  .ip_prot_i                              ( ip_prot_i         ),
  .ip_prot_en_i                           ( ip_prot_en_i      ),
  .port_src_i                             ( port_src_i        ),
  .port_src_en_i                          ( port_src_en_i     ),

  .port_dst_i                             ( port_dst_i        ),
  .port_dst_en_i                          ( port_dst_en_i     ),

  //Classification result outputs
  .tcp_o                                  ( tcp_o             ),
  .udp_o                                  ( udp_o             ),

  .telnet_o                               ( telnet_o          ),
  .ssh_o                                  ( ssh_o             ),
  .et_discover_o                          ( et_discover_o     ),
  .ptp_l4_o                               ( ptp_l4_o          ),

  .icmp_o                                 ( icmp_o            ),
  .dhcp_o                                 ( dhcp_o            ),
  .dns_o                                  ( dns_o             ),
  .twamp_control_o                        ( twamp_control_o   )
);





      assign twamp_test_flow_num_o = '0;
      assign twamp_reflector_pkt_o = 1'b0;
      assign twamp_sender_pkt_o    = 1'b0;


 

assign xcap_filt_res_o = 1'b0;

endmodule
