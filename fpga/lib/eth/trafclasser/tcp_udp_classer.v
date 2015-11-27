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

`include "tcp_udp_classer.vh"

module tcp_udp_classer(
  input        clk_i,
  input        rst_i,
  input        clken_i,

//data inputs
  input [7:0]     ip_prot_i,
  input           ip_prot_en_i,
  input [15:0]    port_src_i,
  input           port_src_en_i,

  input [15:0]    port_dst_i,
  input           port_dst_en_i,

// Classification result outputs
  output logic    tcp_o,
  output logic    udp_o,

  output logic    telnet_o,         
  output logic    ssh_o,
  output logic    et_discover_o,    
  output logic    ptp_l4_o,

  output logic    icmp_o,
  output logic    dhcp_o,
  output logic    dns_o,

  output logic    twamp_control_o
);

logic udp_pkt;
logic tcp_pkt;
logic icmp_pkt;

logic is_telnet;
logic is_ssh;
logic is_et_discover;
logic is_ptp;
logic is_twamp_control;
logic is_dhcp;
logic is_dns;

always_comb
  begin
    tcp_pkt  = ( ip_prot_i == `TCP_PROTO  ) && ip_prot_en_i;
    udp_pkt  = ( ip_prot_i == `UDP_PROTO  ) && ip_prot_en_i;
    icmp_pkt = ( ip_prot_i == `ICMP_PROTO ) && ip_prot_en_i;
  end

assign is_telnet        = (   (   port_dst_i == `TELNET_PORT        ) && port_dst_en_i && tcp_pkt );  
assign is_ssh           = (   (   port_dst_i == `SSH_PORT           ) && port_dst_en_i && tcp_pkt );  

assign is_et_discover   = (   (   port_dst_i == `ET_DISCOVER_PORT   ) && port_dst_en_i && udp_pkt );
assign is_ptp           = (   (   port_dst_i == `PTP_EVENT_PORT     ) || 
                              (   port_dst_i == `PTP_GENERAL_PORT   ) ) && port_dst_en_i && udp_pkt;

assign is_twamp_control = ( ( (   port_src_i == `TWAMP_CONTROL_PORT ) && port_src_en_i ) || 
                            ( (   port_dst_i == `TWAMP_CONTROL_PORT ) && port_dst_en_i ) ) && tcp_pkt;

assign is_dhcp          = ( ( port_dst_i == `DHCP_PORT_A ) ||
                            ( port_dst_i == `DHCP_PORT_B ) ) && udp_pkt;

assign is_dns           =  ( port_dst_i == `DNS_PORT ) && ( tcp_pkt || udp_pkt );                         

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    begin
      tcp_o           <= 1'b0;
      udp_o           <= 1'b0;

      telnet_o        <= 1'b0;
      ssh_o           <= 1'b0;
      et_discover_o   <= 1'b0;
      ptp_l4_o        <= 1'b0;
      twamp_control_o <= 1'b0;

      icmp_o          <= 1'b0;
      dhcp_o          <= 1'b0;
      dns_o           <= 1'b0;
    end
  else
    if( clken_i )
      begin
        tcp_o           <= tcp_pkt;
        udp_o           <= udp_pkt;

        telnet_o        <= is_telnet;
        ssh_o           <= is_ssh;
        et_discover_o   <= is_et_discover;
        ptp_l4_o        <= is_ptp;
        twamp_control_o <= is_twamp_control;

        icmp_o          <= icmp_pkt;
        dhcp_o          <= is_dhcp;
        dns_o           <= is_dns;
      end

endmodule
