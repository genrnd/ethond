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

`include "ipv6_parser.vh"
module ipv6_parser #(parameter max_pos_p = 8)(
  input                  clk_i,
  input                  rst_i,
  input                  srst_i,
  input                  en_i,

  input                  ipv6_en_i,
  input                  ip_6b_n2b_start_i, //1 - ip starts at 6 byte, 
                                            //0 - ip starts at 2 byte of pkt_data_i

//Input pkt interface
  input [63:0]           pkt_data_i,
  input [2:0]            pkt_mod_i,
  input                  pkt_eop_i,                           
  input                  pkt_sop_i,                           
  input                  pkt_en_i,                            

//Output pkt interface
  output logic [63:0]    pkt_data_o,                          
  output       [2:0]     pkt_mod_o,
  output logic           pkt_eop_o,                           
  output logic           pkt_sop_o,                           
  output logic           pkt_en_o,                            

//Status signal
  output logic [127:0]   ipv6_src_o,
  output logic           ipv6_src_en_o,

  output logic [127:0]   ipv6_dst_o,
  output logic           ipv6_dst_en_o,

  output logic [7:0]     next_header_o,
  output logic           next_header_en_o,

  output logic           ipv6_l4_en_o,
  output logic           tcp_udp_en_o

);

logic [max_pos_p-1:0] data_pos; //Input data position
logic [68:0]          data_r0;
logic [68:0]          data_r1;
logic [3:0]           ipv6_version;  //версия ip протокола

logic                 pkt_en_d1;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    begin
      data_r0 <= '0;
      data_r1 <= '0; 
    end
  else
    if( pkt_en_i )
      begin
        data_r0 <= {pkt_mod_i, pkt_sop_i, pkt_eop_i, pkt_data_i};
        data_r1 <= data_r0;
      end

assign {pkt_mod_o, pkt_sop_o, pkt_eop_o, pkt_data_o} = data_r0;


always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    pkt_en_d1 <= 1'b0;
  else
    pkt_en_d1 <= pkt_en_i;

assign pkt_en_o = pkt_en_d1;

//Position counter (as shift register)
always_ff @(posedge clk_i, posedge rst_i)
  if(rst_i)
    begin 
      data_pos    <= 1;
    end  
  else
    if(pkt_en_i)
      if(pkt_eop_i)
        data_pos <= 1; //по концу пакета обнуляет бегущую едницу
      else
        if(ipv6_en_i)   
          data_pos <= {data_pos[max_pos_p-2:0],1'b0};

        //Get IP version 
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    ipv6_version     <= '0;
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          ipv6_version <= '0;
        end
      else
        if (ipv6_en_i)
          if (data_pos[`IPV6_VER_POS])
            if (ip_6b_n2b_start_i)
              ipv6_version <= pkt_data_i[`IPV6_VER_6B];
            else
              ipv6_version <= pkt_data_i[`IPV6_VER_2B];

//Get IP source
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      ipv6_src_o     <= '0;
      ipv6_src_en_o  <= 1'd0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          ipv6_src_o <= '0;
          ipv6_src_en_o  <= 1'd0;
        end
      else
      /*  if (ip_en_i)*/
          if (~ip_6b_n2b_start_i)
            begin
              if (data_pos[`IPV6_SRC_2B_POS]) 
                begin
                  ipv6_src_o <= {data_r1[`IPV6_SRC_2B_B0_B8],  data_r1[`IPV6_SRC_2B_B1_B9],
                                 data_r1[`IPV6_SRC_2B_B2_B10], data_r1[`IPV6_SRC_2B_B3_B11], 
                                 data_r1[`IPV6_SRC_2B_B4_B12], data_r1[`IPV6_SRC_2B_B5_B13], 
                                 data_r0[`IPV6_SRC_2B_B6_B14], data_r0[`IPV6_SRC_2B_B7_B15],
                                 data_r0[`IPV6_SRC_2B_B0_B8],  data_r0[`IPV6_SRC_2B_B1_B9],
                                 data_r0[`IPV6_SRC_2B_B2_B10], data_r0[`IPV6_SRC_2B_B3_B11],
                                 data_r0[`IPV6_SRC_2B_B4_B12], data_r0[`IPV6_SRC_2B_B5_B13],
                                 pkt_data_i[`IPV6_SRC_2B_B6_B14], pkt_data_i[`IPV6_SRC_2B_B7_B15]
                                 };
                  ipv6_src_en_o  <= 1'd1;
                end
            end
          else //not ip_6b_n2b_start_i
            begin
              if (data_pos[`IPV6_SRC_6B_POS])
                begin
                  ipv6_src_o <= {data_r1[`IPV6_SRC_6B_B0_B8],  data_r1[`IPV6_SRC_6B_B1_B9],
                                 data_r0[`IPV6_SRC_6B_B2_B10], data_r0[`IPV6_SRC_6B_B3_B11], 
                                 data_r0[`IPV6_SRC_6B_B4_B12], data_r0[`IPV6_SRC_6B_B5_B13], 
                                 data_r0[`IPV6_SRC_6B_B6_B14], data_r0[`IPV6_SRC_6B_B7_B15],
                                 data_r0[`IPV6_SRC_6B_B0_B8],  data_r0[`IPV6_SRC_6B_B1_B9],
                                 pkt_data_i[`IPV6_SRC_6B_B2_B10], pkt_data_i[`IPV6_SRC_6B_B3_B11],
                                 pkt_data_i[`IPV6_SRC_6B_B4_B12], pkt_data_i[`IPV6_SRC_6B_B5_B13],
                                 pkt_data_i[`IPV6_SRC_6B_B6_B14], pkt_data_i[`IPV6_SRC_6B_B7_B15]
                                 };
                  ipv6_src_en_o  <= 1'd1;
                end
            end

 //Get IP destination
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      ipv6_dst_o     <= '0;
      ipv6_dst_en_o  <= 1'd0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          ipv6_dst_o <= '0;
          ipv6_dst_en_o  <= 1'd0;
        end
      else
      /*  if (ip_en_i)*/
          if (~ip_6b_n2b_start_i)
            begin
              if (data_pos[`IPV6_DST_2B_POS])
                begin
                  ipv6_dst_o <= {data_r1[`IPV6_SRC_2B_B0_B8],  data_r1[`IPV6_SRC_2B_B1_B9],
                                 data_r1[`IPV6_SRC_2B_B2_B10], data_r1[`IPV6_SRC_2B_B3_B11], 
                                 data_r1[`IPV6_SRC_2B_B4_B12], data_r1[`IPV6_SRC_2B_B5_B13], 
                                 data_r0[`IPV6_SRC_2B_B6_B14], data_r0[`IPV6_SRC_2B_B7_B15],
                                 data_r0[`IPV6_SRC_2B_B0_B8],  data_r0[`IPV6_SRC_2B_B1_B9],
                                 data_r0[`IPV6_SRC_2B_B2_B10], data_r0[`IPV6_SRC_2B_B3_B11],
                                 data_r0[`IPV6_SRC_2B_B4_B12], data_r0[`IPV6_SRC_2B_B5_B13],
                                 pkt_data_i[`IPV6_SRC_2B_B6_B14], pkt_data_i[`IPV6_SRC_2B_B7_B15]
                                 };
                  ipv6_dst_en_o  <= 1'd1;
                end
            end
          else //not ip_6b_n2b_start_i
            begin
              if (data_pos[`IPV6_DST_6B_POS])
                begin
                  ipv6_dst_o <= {data_r1[`IPV6_SRC_6B_B0_B8],  data_r1[`IPV6_SRC_6B_B1_B9],
                                 data_r0[`IPV6_SRC_6B_B2_B10], data_r0[`IPV6_SRC_6B_B3_B11], 
                                 data_r0[`IPV6_SRC_6B_B4_B12], data_r0[`IPV6_SRC_6B_B5_B13], 
                                 data_r0[`IPV6_SRC_6B_B6_B14], data_r0[`IPV6_SRC_6B_B7_B15],
                                 data_r0[`IPV6_SRC_6B_B0_B8],  data_r0[`IPV6_SRC_6B_B1_B9],
                                 pkt_data_i[`IPV6_SRC_6B_B2_B10], pkt_data_i[`IPV6_SRC_6B_B3_B11],
                                 pkt_data_i[`IPV6_SRC_6B_B4_B12], pkt_data_i[`IPV6_SRC_6B_B5_B13],
                                 pkt_data_i[`IPV6_SRC_6B_B6_B14], pkt_data_i[`IPV6_SRC_6B_B7_B15]
                                 };
                  ipv6_dst_en_o  <= 1'd1;
                end
            end

//Get IP proto 
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      next_header_o     <= '0;
      next_header_en_o  <= '0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          next_header_o <= '0;
          next_header_en_o  <= '0;
        end
      else
        if(ip_6b_n2b_start_i)
          begin
            if(data_pos[`IPV6_NH_6B_POS])
               begin
                 next_header_o <= pkt_data_i[`IPV6_NH_6B_B0];
                 next_header_en_o  <= '1;
               end
          end
        else
          begin
            if(data_pos[`IPV6_NH_2B_POS])
               begin
                 next_header_o <= pkt_data_i[`IPV6_NH_2B_B0];
                 next_header_en_o  <= '1;
               end
          end

logic tcp_udp_prot_w;
//Assert l4_enable: протокол udp или tcp + ipv4 + длина заголовка 20 байт

always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    tcp_udp_en_o <= 1'b0;
  else
    if (pkt_en_i)
      if (pkt_eop_i)
        tcp_udp_en_o <= 1'b0;
      else
        if (ip_6b_n2b_start_i)
          begin
            if(data_pos[`L4_IPV6_START_6B_POS])
              //Assert if udp or tcp protocol and ipv4 and header length 20 byte
              tcp_udp_en_o <= next_header_en_o & tcp_udp_prot_w;
          end
        else //выравнивание по второму байту
          begin
            if(data_pos[`L4_IPV6_START_2B_POS])
              //Assert if udp or tcp protocol and ipv4 and header length 20 byte
              tcp_udp_en_o <= next_header_en_o & tcp_udp_prot_w;
          end

assign tcp_udp_prot_w = (next_header_o == `UDP_PROT) || (next_header_o == `TCP_PROT);



always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    ipv6_l4_en_o <= 1'b0;
  else
    if (pkt_en_i)
      if (pkt_eop_o)
        ipv6_l4_en_o <= 1'b0;
      else
        if (ip_6b_n2b_start_i)
          begin
            if(data_pos[`L4_IPV6_START_6B_POS])
              ipv6_l4_en_o <= next_header_en_o;
          end
        else //выравнивание по второму байту
          begin
            if(data_pos[`L4_IPV6_START_2B_POS])
              ipv6_l4_en_o <= next_header_en_o;
          end

          
endmodule
