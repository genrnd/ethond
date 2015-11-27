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

`include "trafparser.vh"

module trafparser(
  input clk_i,
  input rst_i,

  input en_i,   //global enable on all module

  //Packet rx interface
  input         pkt_sop_i, //start of packet
  input  [2:0]  pkt_mod_i, 
  input         pkt_eop_i, //end of packet
  input         pkt_en_i,  //packet data enable
  input [63:0]  pkt_data_i,

  //eop для того что бы знать когда сохранять каждый
  //из уровней пакета
  output  logic         pkt_l2_eop_o,
  output  logic         pkt_l25_eop_o,
  output  logic         pkt_l3_eop_o,
  output  logic         pkt_l4_eop_o,

  //output status
  output  logic  [47:0] macd_o,   //Destiantion Mac address of input packet
  output                macd_en_o,//

  output  logic  [47:0] macs_o,   //Source Mac address of input packet
  output                macs_en_o,

  //ethertype outputs
  output logic [15:0]   ethtype_o,     //ethertype field
  output logic          ethtype_en_o,  //enable для ethtype_o

  //vlan0 outputs
  output logic [15:0]   vlan0_vid_o,    //vlan0 vlad ID (+ PCP, CFI bits)
  output logic          vlan0_vid_en_o, //enable for vlan0_vid_o

  //vlan1 outputs
  output logic [15:0]   vlan1_vid_o,    //vlan1 vlad ID (+ PCP, CFI bits)
  output logic          vlan1_vid_en_o, //enable for vlan1_vid_o

  //vlan2 outputs
  output logic [15:0]   vlan2_vid_o,    //vlan2 vlad ID (+ PCP, CFI bits)
  output logic          vlan2_vid_en_o, //enable for vlan2_vid_o
  
  output logic [1:0]    vlan_cnt_o,
  
  output logic [31:0]   mpls0_o,  
  output logic          mpls0_en_o,
          
  output logic [31:0]   mpls1_o,  
  output logic          mpls1_en_o,
          
  output logic [31:0]   mpls2_o,  
  output logic          mpls2_en_o,

  output logic [1:0]    mpls_cnt_o,

  //ip level outputs
  output logic [31:0]   ip_src_o,    
  output logic          ip_src_en_o, 
                    
  output logic [31:0]   ip_dst_o,    
  output logic          ip_dst_en_o, 
                   
  output logic [127:0]  ipv6_src_o,
  output logic          ipv6_src_en_o,

  output logic [127:0]  ipv6_dst_o,
  output logic          ipv6_dst_en_o,

  output logic [7:0]    ip_prot_o,   
  output logic          ip_prot_en_o,

  output logic [15:0]   port_src_o,
  output logic          port_src_en_o,
                                      
  output logic [15:0]   port_dst_o,
  output logic          port_dst_en_o,
  
  output logic [7:0]    ip_tos_o,   //type of service
  output logic          ip_tos_en_o,


  output logic [15:0]   ip_ident_o, //identification
  output logic          ip_ident_en_o,

  output logic [15:0]   ip_flags_offset_o, //3'b flags + 13'b offset
  output logic          ip_flags_offset_en_o,
  
  output logic          ip_offset_gt_zero_o,
  
  output logic [8:0]    tcp_flags_o,
  output logic          tcp_flags_en_o

);

//Соединение l2_parser и mpls_parser
logic  [63:0] l2p_pkt_data_w;
logic         l2p_pkt_eop_w;
logic         l2p_pkt_sop_w;  
logic   [2:0] l2p_pkt_mod_w;  
logic         l2p_pkt_en_w; 
logic         l2p_l25_en_w;

logic         ip_en_w;
logic         ipv6_en_w;
logic         ip_6b_n2b_start_w;
logic         ip_6b_n2b_start_d0;

logic  [63:0] l25p_pkt_data_w;
logic         l25p_pkt_eop_w;
logic         l25p_pkt_sop_w;  
logic   [2:0] l25p_pkt_mod_w;  
logic         l25p_pkt_en_w;

logic  [63:0] l3p_pkt_data_w;
logic         l3p_pkt_eop_w;
logic         l3p_pkt_sop_w;  
logic   [2:0] l3p_pkt_mod_w;  
logic         l3p_pkt_en_w; 

logic         tcp_udp_en_w;
logic         tcp_udp_ipv6_en_w;
logic         ipv6_l4_en_w;
logic         ipv4_l4_en_w;
logic         ipv6_cont_en;

logic [7:0]       ip_prot_w;
logic             ip_prot_en_w;
logic [7:0]       next_header_w;
logic             next_header_en_w;


assign pkt_l2_eop_o  = pkt_eop_i;
assign pkt_l25_eop_o = l2p_pkt_eop_w;
assign pkt_l3_eop_o  = l25p_pkt_eop_w;
assign pkt_l4_eop_o  = l3p_pkt_eop_w;

l2_parser #(`MAX_POS_L2) l2_parser(
.clk_i                                  ( clk_i       ),
.rst_i                                  ( rst_i       ),
//Reset module at the end of every packet
.srst_i                                 ( '0          ),
.en_i                                   ( en_i        ),

//Input pkt interface
.pkt_data_i                             ( pkt_data_i  ),
.pkt_eop_i                              ( pkt_eop_i   ),
.pkt_sop_i                              ( pkt_sop_i   ),
.pkt_en_i                               ( pkt_en_i    ),
.pkt_mod_i                              ( pkt_mod_i   ),

//Output pkt interface
.pkt_data_o                             ( l2p_pkt_data_w ),
.pkt_eop_o                              ( l2p_pkt_eop_w  ),
.pkt_sop_o                              ( l2p_pkt_sop_w  ),
.pkt_mod_o                              ( l2p_pkt_mod_w  ),
.pkt_en_o                               ( l2p_pkt_en_w   ),

.l25_en_o                               ( l2p_l25_en_w),
.macd_o                                 ( macd_o      ),
.macd_en_o                              ( macd_en_o   ),
.macs_o                                 ( macs_o      ),
.macs_en_o                              ( macs_en_o   ),
.ethtype_o                              ( ethtype_o         ),
.ethtype_en_o                           ( ethtype_en_o      ),
.vlan0_vid_o                            ( vlan0_vid_o       ),
.vlan0_vid_en_o                         ( vlan0_vid_en_o    ),
.vlan1_vid_o                            ( vlan1_vid_o       ),
.vlan1_vid_en_o                         ( vlan1_vid_en_o    ),
.vlan2_vid_o                            ( vlan2_vid_o       ),
.vlan2_vid_en_o                         ( vlan2_vid_en_o    ),
.vlan_cnt_o                             ( vlan_cnt_o        )
);


mpls_parser mpls_parser(
.clk_i                                  ( clk_i                ),
.rst_i                                  ( rst_i                ),
.srst_i                                 ( '0                   ),
.en_i                                   ( en_i                 ),

.ethtype_i                              ( ethtype_o            ),
.l25_en_i                               ( l2p_l25_en_w         ),

  //нужна информация о наличии mpls меток, чтобы понять где находятся
  //mpls метки
.vlan0_vid_en_i                         ( vlan0_vid_en_o    ),
.vlan1_vid_en_i                         ( vlan1_vid_en_o    ),
.vlan2_vid_en_i                         ( vlan2_vid_en_o    ),

//Input pkt interface
.pkt_data_i                             (l2p_pkt_data_w  ),
.pkt_eop_i                              (l2p_pkt_eop_w   ),
.pkt_sop_i                              (l2p_pkt_sop_w   ),
.pkt_mod_i                              (l2p_pkt_mod_w   ),
.pkt_en_i                               (l2p_pkt_en_w    ),

//Output pkt interface
.pkt_data_o                             ( l25p_pkt_data_w),
.pkt_eop_o                              ( l25p_pkt_eop_w ),
.pkt_sop_o                              ( l25p_pkt_sop_w ),
.pkt_mod_o                              ( l25p_pkt_mod_w ),
.pkt_en_o                               ( l25p_pkt_en_w  ),

.ip_en_o                                ( ip_en_w           ),
.ipv6_en_o                              ( ipv6_en_w         ),
.ip_6b_n2b_start_o                      ( ip_6b_n2b_start_w ),

  //mpls outputs (max 3 labels)
.mpls0_o                                ( mpls0_o           ),
.mpls0_en_o                             ( mpls0_en_o        ),

.mpls1_o                                ( mpls1_o           ),
.mpls1_en_o                             ( mpls1_en_o        ),

.mpls2_o                                ( mpls2_o           ),
.mpls2_en_o                             ( mpls2_en_o        ),
.mpls_cnt_o                             ( mpls_cnt_o        )
);

ip_parser ip_parser(
.clk_i                                  ( clk_i             ),
.rst_i                                  ( rst_i             ),
.srst_i                                 ( '0                ),
.en_i                                   ( en_i              ),

.ip_en_i                                ( ip_en_w           ),
.ip_6b_n2b_start_i                      ( ip_6b_n2b_start_w ),
                                            //0 - ip starts at 2 byte of pkt_data_i

//Input pkt interface
.pkt_data_i                             ( l25p_pkt_data_w ),
.pkt_eop_i                              ( l25p_pkt_eop_w  ),
.pkt_sop_i                              ( l25p_pkt_sop_w  ),
.pkt_en_i                               ( l25p_pkt_en_w   ),
.pkt_mod_i                              ( l25p_pkt_mod_w  ),

//Output pkt interface
.pkt_data_o                             ( l3p_pkt_data_w       ),
.pkt_eop_o                              ( l3p_pkt_eop_w        ),
.pkt_sop_o                              ( l3p_pkt_sop_w        ),
.pkt_en_o                               ( l3p_pkt_en_w         ),
.pkt_mod_o                              ( l3p_pkt_mod_w        ),
//Status signal
.ip_src_o                               ( ip_src_o             ),
.ip_src_en_o                            ( ip_src_en_o          ),
                                          
.ip_dst_o                               ( ip_dst_o             ),
.ip_dst_en_o                            ( ip_dst_en_o          ),
                                          
.ip_prot_o                              ( ip_prot_w            ),
.ip_prot_en_o                           ( ip_prot_en_w         ),

.ip_ident_o                             ( ip_ident_o           ),
.ip_ident_en_o                          ( ip_ident_en_o        ),

.ip_tos_o                               ( ip_tos_o             ),
.ip_tos_en_o                            ( ip_tos_en_o          ),

.ip_flags_offset_o                      ( ip_flags_offset_o    ),
.ip_flags_offset_en_o                   ( ip_flags_offset_en_o ),

.ip_offset_gt_zero_o                    ( ip_offset_gt_zero_o  ),
.ipv4_l4_en_o                           ( ipv4_l4_en_w         ),
.tcp_udp_en_o                           ( tcp_udp_en_w         )

);

always_comb
begin
  if(ipv6_en_w)
    begin
      ip_prot_o = next_header_w;
      ip_prot_en_o = next_header_en_w;
    end
  else
    begin
      ip_prot_o = ip_prot_w;
      ip_prot_en_o = ip_prot_en_w;
    end
end


ipv6_parser ipv6_parser(
.clk_i                                  ( clk_i             ),
.rst_i                                  ( rst_i             ),
.srst_i                                 ( 1'b0              ),
.en_i                                   ( en_i              ),

.ipv6_en_i                              ( ipv6_en_w         ),
.ip_6b_n2b_start_i                      ( ip_6b_n2b_start_w ),
                                            //0 - ip starts at 2 byte of pkt_data_i

//Input pkt interface
.pkt_data_i                             ( l25p_pkt_data_w ),
.pkt_eop_i                              ( l25p_pkt_eop_w  ),
.pkt_sop_i                              ( l25p_pkt_sop_w  ),
.pkt_en_i                               ( l25p_pkt_en_w   ),
.pkt_mod_i                              ( l25p_pkt_mod_w  ),


//Output pkt interface
.pkt_data_o                             (         ),
.pkt_mod_o                              (         ),
.pkt_eop_o                              (         ),
.pkt_sop_o                              (         ),
.pkt_en_o                               (         ),

//Status signal
.ipv6_src_o                             ( ipv6_src_o        ),
.ipv6_src_en_o                          ( ipv6_src_en_o     ),

.ipv6_dst_o                             ( ipv6_dst_o        ),
.ipv6_dst_en_o                          ( ipv6_dst_en_o     ),

.next_header_o                          ( next_header_w     ),
.next_header_en_o                       ( next_header_en_w  ),
.ipv6_l4_en_o                           ( ipv6_l4_en_w      ),
.tcp_udp_en_o                           ( tcp_udp_ipv6_en_w )
);

delay_sv #(1,2) l2_loop_delay (
  .clk ( clk_i                 ),
  .rst ( rst_i                 ),
  .ena ( en_i && l25p_pkt_en_w ),
  .d   ( ip_6b_n2b_start_w     ),
  .q   ( ip_6b_n2b_start_d0    )
);


logic tcp_en_w;
assign tcp_en_w = ((tcp_udp_en_w || tcp_udp_ipv6_en_w) & (ip_prot_o == 'd6));

tcp_udp_parser tcp_udp_parser(
.clk_i                                  ( clk_i             ),
.rst_i                                  ( rst_i             ),
.tcp_en_i                               ( tcp_en_w          ),            //only tcp, for parsing tcp flags
.tcp_udp_ipv4_en_i                      ( tcp_udp_en_w      ), 
.tcp_udp_ipv6_en_i                      ( tcp_udp_ipv6_en_w ),
.ip_6b_n2b_start_i                      ( ip_6b_n2b_start_d0),
                                            //0 - ip starts at 2 byte of pkt_data_i

//Input pkt interface
.pkt_data_i                             ( l3p_pkt_data_w    ),
.pkt_eop_i                              ( l3p_pkt_eop_w     ),
.pkt_sop_i                              ( l3p_pkt_sop_w     ),
.pkt_en_i                               ( l3p_pkt_en_w      ),
.pkt_mod_i                              ( l3p_pkt_mod_w     ),

//Output pkt interface
.pkt_data_o                             ( ),
.pkt_mod_o                              ( ),
.pkt_eop_o                              ( ),
.pkt_sop_o                              ( ),
.pkt_en_o                               ( ),
//Status signal
.port_src_o                             ( port_src_o        ),
.port_src_en_o                          ( port_src_en_o     ),
.port_dst_o                             ( port_dst_o        ),
.port_dst_en_o                          ( port_dst_en_o     ),
.tcp_flags_o                            ( tcp_flags_o       ),
.tcp_flags_en_o                         ( tcp_flags_en_o    )
);

endmodule
