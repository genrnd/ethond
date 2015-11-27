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
Module: l2_classer
Purpose: classification (comparison layer 2 fields) of packets by predetermined 
         values:
           broadcast (all 1's in MAC destination) 
           multicast (1 in LS bit of MS byte (first byte) in MAC destination)
           unicast   (MAC destination determined by higher level)
Authors: kod,alex     
*/

`include "l2_classer.vh"

module l2_classer(
  input        clk_i,
  input        rst_i,
  input        clken_i,

//data inputs
  input [47:0] macs_i,    //mac source address
  input        macs_en_i, //mac source enable

  input [47:0] macd_i,    //mac dest address
  input        macd_en_i, //mac dest enable

  //ethertype
  input [15:0] ethtype_i,     //ethertype field
  input        ethtype_en_i,  //enable для ethtype_o

  //vlan0
  input [15:0] vlan0_vid_i,    //vlan0 vlad ID (+ PCP, CFI bits)
  input        vlan0_vid_en_i, //enable for vlan0_vid_o

  //vlan1
  input [15:0] vlan1_vid_i,    //vlan1 vlad ID (+ PCP, CFI bits)
  input        vlan1_vid_en_i, //enable for vlan1_vid_o

  //vlan2
  input [15:0] vlan2_vid_i,    //vlan2 vlad ID (+ PCP, CFI bits)
  input        vlan2_vid_en_i,  //enable for vlan2_vid_o

  input [15:0] frm_len_i, //frame length

// control
  nic_ctrl_if.app nic_if,

  input [15:0]    frm_len_min_i,  // minimum allowed frame size
  input [15:0]    frm_len_max_i,  // maximum allowed frame size
 
// Classification result outputs
  output logic ip_o,           // ip frame
  output logic oam_o,          // oam frame
  output logic ethertype_lb_o, // keep alive frame (ethertype 0x9000)
  output logic oversize_o,     // oversize frame(>maximum allowed)
  output logic runt_o,         // runt frame(<minimum allowed)
  output logic broadcast_o,    // broadcast detected
  output logic multicast_o,    // muticast detected
  output logic unicast_o,      // unicast detected
  output logic usercast_o,     // our mac detected
  output logic nic_encaps_o,   // packet FROM CPU: have encaps vlan
  output logic samemacs_o,     // same mac addresses detected
  output logic ptp_l2_o,       // ptp l2 detected
  output logic arp_o           // ARP-message detected
);

//Broadcast detection
always @(posedge clk_i, posedge rst_i)
  if(rst_i)
    broadcast_o <= 1'b0;
  else
    if(clken_i)
      if( ( macd_i == '1 ) && macd_en_i )
        broadcast_o <= 1'b1;
      else
        broadcast_o <= 1'b0;

//Multicast detection
always @(posedge clk_i, posedge rst_i)
  if(rst_i)
    multicast_o <= 1'b0;
  else
    if(clken_i)
      if( (macd_i != '1) && (macd_i[0] == 1'b1) && macd_en_i )
        //исключаем появление broadcast'ов (не ревно всем единицам)
        multicast_o <= 1'b1;
      else
        multicast_o <= 1'b0;

assign unicast_o = ( !broadcast_o ) && ( !multicast_o );

logic main_host_mac_match;
logic alt_host_mac_match;

assign main_host_mac_match = ( macd_i == nic_if.host_mac     );
assign alt_host_mac_match  = ( macd_i == nic_if.alt_host_mac ) && nic_if.also_use_alt_host_mac; 

//Unicast detection
always @(posedge clk_i, posedge rst_i)
  if(rst_i)
    usercast_o <= 1'b0;
  else
    if(clken_i)
      if( ( main_host_mac_match || alt_host_mac_match ) && macd_en_i )
        usercast_o <= 1'b1;
      else
        usercast_o <= 1'b0;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    nic_encaps_o <= 1'b0;
  else
    if( clken_i )
      begin
        if( ( vlan0_vid_i[11:0] == nic_if.encaps_vlan ) && vlan0_vid_en_i )
          nic_encaps_o <= 1'b1;
        else
          nic_encaps_o <= 1'b0;
      end

//Same macs detection
always @(posedge clk_i, posedge rst_i)
  if(rst_i)
    samemacs_o <= 1'b0;
  else
    if(clken_i)
      if( ( macd_i == macs_i ) && macs_en_i && macd_en_i)
       samemacs_o <= 1'b1;
      else
       samemacs_o <= 1'b0;

//Runt frame detection
always @(posedge clk_i, posedge rst_i)
  if(rst_i)
    runt_o <= '0;
  else
    if (clken_i)
      if(frm_len_i < frm_len_min_i)
        runt_o <= '1;
      else
        runt_o <= '0;

//Oversized frame detection
always @(posedge clk_i, posedge rst_i)
  if(rst_i)
    oversize_o <= '0;
  else
    if (clken_i)
      if (frm_len_i > frm_len_max_i)
        oversize_o <= '1;
      else
        oversize_o <= '0;


logic is_ipv4_ethtype;

// считаем, что если пакет с mpls, то это пакет ipv4.
// аналогично делается в парсере, так что...
assign is_ipv4_ethtype = ( ( ethtype_i == `IP_ETHTYPE ) || 
                           ( ethtype_i == `MPLS_TYPE0 ) || 
                           ( ethtype_i == `MPLS_TYPE1 ) );
//IP frame detection
always @(posedge clk_i, posedge rst_i)
  if( rst_i )
    ip_o <= '0;
  else
    if( clken_i )
      if( is_ipv4_ethtype && ethtype_en_i )
        ip_o <= '1;
      else
        ip_o <= '0;

//Keep alive frame detection
always @(posedge clk_i, posedge rst_i)
  if(rst_i)
    ethertype_lb_o <= '0;
  else
    if(clken_i)
      if( ( ethtype_i == `LOOPBACK_ETHTYPE ) && ethtype_en_i )
        ethertype_lb_o <= '1;
      else
        ethertype_lb_o <= '0;

//OAM frame detection
always @(posedge clk_i, posedge rst_i)
  if(rst_i)
    oam_o <= '0;
  else
    if(clken_i)
      if( ( macd_i == `OAM_MAC_ADDRESS ) && macd_en_i )
        oam_o <= '1;
      else
        oam_o <= '0;

// PTP L2 frame detection
always @(posedge clk_i, posedge rst_i)
  if( rst_i )
    ptp_l2_o <= 1'b0;
  else
    if( clken_i )
      if( ( ethtype_i == `PTP_ETHTYPE ) && ethtype_en_i )
        ptp_l2_o <= 1'b1;
      else
        ptp_l2_o <= 1'b0;

always @(posedge clk_i, posedge rst_i)
  if( rst_i )
    arp_o <= '0;
  else
    if( clken_i )
      if( ( ethtype_i == `ARP_ETHTYPE ) && ethtype_en_i )
        arp_o <= 1'b1;
      else
        arp_o <= 1'b0;

endmodule
