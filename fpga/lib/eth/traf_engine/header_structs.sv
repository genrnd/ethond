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

typedef struct packed{

  logic [47:0] macd;
  logic        macd_en;
  
  logic [47:0] macs;
  logic        macs_en;

  logic [15:0] ethtype;
  logic        ethtype_en;

  logic [15:0] vlan0_vid;
  logic        vlan0_vid_en;
  
  logic [15:0] vlan1_vid;
  logic        vlan1_vid_en;
  
  logic [15:0] vlan2_vid;
  logic        vlan2_vid_en;
  
  logic [1:0]  vlan_cnt;

} head_l2_s;

typedef struct packed{

  logic [31:0] mpls0;
  logic        mpls0_en;
  
  logic [31:0] mpls1;
  logic        mpls1_en;
  
  logic [31:0] mpls2;
  logic        mpls2_en;
  
  logic [1:0]  mpls_cnt;

} head_l25_s;

typedef struct packed{
  
  logic  [31:0] ip_src;
  logic         ip_src_en;
  
  logic  [31:0] ip_dst;
  logic         ip_dst_en;
  
  logic   [7:0] ip_prot;
  logic         ip_prot_en;
  
  logic  [15:0] ip_ident;
  logic         ip_ident_en;

  logic  [15:0] ip_flags_offset;
  logic         ip_flags_offset_en;

  logic         ip_offset_gt_zero;

  logic  [15:0] ip_len;
  logic         ip_len_en;
  
  logic   [7:0] ip_tos;
  logic         ip_tos_en;

  logic [127:0] ipv6_src;
  logic         ipv6_src_en;

  logic [127:0] ipv6_dst;
  logic         ipv6_dst_en;

} head_l3_s;

typedef struct packed{

  logic [15:0] port_src;
  logic        port_src_en;
  
  logic [15:0] port_dst;
  logic        port_dst_en;

  logic  [8:0] tcp_flags;
  logic        tcp_flags_en;

} head_l4_s;
