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


module ip_parser #(parameter max_pos_p = 5)(
  input                  clk_i,
  input                  rst_i,
  input                  srst_i,
  input                  en_i,

  input                  ip_en_i,
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
  output logic [31:0]    ip_src_o,
  output logic           ip_src_en_o,

  output logic [31:0]    ip_dst_o,
  output logic           ip_dst_en_o,

  output logic [7:0]     ip_prot_o,
  output logic           ip_prot_en_o,
  
  output logic [7:0]     ip_tos_o,   //type of service
  output logic           ip_tos_en_o,

  output logic [15:0]    ip_ident_o, //identification
  output logic           ip_ident_en_o,

  output logic [15:0]    ip_flags_offset_o, //3'b flags + 13'b offset
  output logic           ip_flags_offset_en_o,

  output logic           ip_offset_gt_zero_o,

  output logic           ipv4_l4_en_o,   //enable for l4
  output logic           tcp_udp_en_o

);

`include "ip_parser.vh"
logic [max_pos_p-1:0] data_pos; //Input data position
logic [68:0]          data_r0;
logic [3:0]           ip_length;   //длина ip заголовка
logic [3:0]           ip_version;  //версия ip протокола
logic                 pkt_en_d1;

always_ff @(posedge clk_i or posedge rst_i)
  if( rst_i )
    data_r0 <= '0; 
  else
    if( pkt_en_i )
      data_r0 <= {pkt_mod_i, pkt_sop_i, pkt_eop_i, pkt_data_i};


always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    pkt_en_d1 <= 1'b0;
  else
    pkt_en_d1 <= pkt_en_i;

assign {pkt_mod_o, pkt_sop_o, pkt_eop_o, pkt_data_o} = data_r0;

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
        if(ip_en_i)   //позиция отсчитывает только слова уровня 2.5
          data_pos <= {data_pos[max_pos_p-2:0],1'b0};

//Get IP source
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      ip_src_o     <= '0;
      ip_src_en_o  <= 1'd0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          ip_src_o <= '0;
          ip_src_en_o  <= 1'd0;
        end
      else
      /*  if (ip_en_i)*/
          if (~ip_6b_n2b_start_i)
            begin
              if (data_pos[`IP_SRC_2B_POS]) //2
                begin
                  ip_src_o <= {data_r0[`IP_SRC_2B_B3], data_r0[`IP_SRC_2B_B2],
                               pkt_data_i[`IP_SRC_2B_B1], pkt_data_i[`IP_SRC_2B_B0]};
                  ip_src_en_o  <= 1'd1;
                end
            end
          else //not ip_6b_n2b_start_i
            begin
              if (data_pos[`IP_SRC_6B_POS])//3
                begin
                  ip_src_o <= {pkt_data_i[`IP_SRC_6B_B3], pkt_data_i[`IP_SRC_6B_B2],
                               pkt_data_i[`IP_SRC_6B_B1], pkt_data_i[`IP_SRC_6B_B0]};
                  ip_src_en_o  <= 1'd1;
                end
            end

//Get IP destination
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      ip_dst_o     <= '0;
      ip_dst_en_o  <= 1'd0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          ip_dst_o <= '0;
          ip_dst_en_o  <= 1'd0;
        end
      else
      /*  if (ip_en_i)*/
          if (~ip_6b_n2b_start_i)
            begin
              if (data_pos[`IP_DST_2B_POS])//3
                begin
                  ip_dst_o <= {pkt_data_i[`IP_DST_2B_B3], pkt_data_i[`IP_DST_2B_B2],
                               pkt_data_i[`IP_DST_2B_B1], pkt_data_i[`IP_DST_2B_B0]};
                  ip_dst_en_o  <= 1'd1;
                end
            end
          else //not ip_6b_n2b_start_i
            begin
              if (data_pos[`IP_DST_6B_POS]) //2
                begin
                  ip_dst_o <= {data_r0[`IP_DST_6B_B3], data_r0[`IP_DST_6B_B2],
                               pkt_data_i[`IP_DST_6B_B1], pkt_data_i[`IP_DST_6B_B0]};
                  ip_dst_en_o  <= 1'd1;
                end
            end


//Get IP version 
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    ip_version     <= '0;
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          ip_version <= '0;
        end
      else
        if (ip_en_i)
          if (data_pos[`IP_VER_POS])
            if (ip_6b_n2b_start_i)
              ip_version <= pkt_data_i[`IP_VER_6B];
            else
              ip_version <= pkt_data_i[`IP_VER_2B];

//Get TOS
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      ip_tos_o     <= '0;
      ip_tos_en_o  <= '0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          ip_tos_o    <= '0;
          ip_tos_en_o <= '0;
        end
      else
        if (ip_en_i)
          if (data_pos[`IP_TOS_POS])
            begin
              ip_tos_en_o <= '1;
              if (ip_6b_n2b_start_i)
                ip_tos_o <= pkt_data_i[`IP_TOS_6B];
              else
                ip_tos_o <= pkt_data_i[`IP_TOS_2B];
            end


//Get flags_offset 
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      ip_flags_offset_o     <= '0;
      ip_flags_offset_en_o  <= '0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          ip_flags_offset_o <= '0;
          ip_flags_offset_en_o  <= '0;
        end
      else
        if (ip_en_i)
          if (data_pos[`IP_FLOFF_POS])
            begin
              ip_flags_offset_en_o  <= '1;
              if (ip_6b_n2b_start_i)
                ip_flags_offset_o <= {pkt_data_i[`IP_FLOFF_6B_B1], pkt_data_i[`IP_FLOFF_6B_B0]};
              else
                ip_flags_offset_o <= {pkt_data_i[`IP_FLOFF_2B_B1], pkt_data_i[`IP_FLOFF_2B_B0]};
            end

assign ip_offset_gt_zero_o = ( ip_flags_offset_o[12:0] > 13'd0 ) && ip_flags_offset_en_o;

//Get flags_offset 
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      ip_ident_o     <= '0;
      ip_ident_en_o  <= '0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          ip_ident_o <= '0;
          ip_ident_en_o  <= '0;
        end
      else
        if(ip_en_i)
          if (ip_6b_n2b_start_i)
            begin
              if (data_pos[`IP_IDENT_6B_POS])
                begin
                  ip_ident_en_o  <= '1;
                  ip_ident_o <= {pkt_data_i[`IP_IDENT_6B_B1], pkt_data_i[`IP_IDENT_6B_B0]};
                end
            end
          else
            begin
              if (data_pos[`IP_IDENT_2B_POS])
                begin
                  ip_ident_en_o  <= '1;
                  ip_ident_o <= {pkt_data_i[`IP_IDENT_2B_B1], pkt_data_i[`IP_IDENT_2B_B0]};
                end
          end

//Get IP proto 
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      ip_prot_o     <= '0;
      ip_prot_en_o  <= '0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          ip_prot_o <= '0;
          ip_prot_en_o  <= '0;
        end
      else
        if (data_pos[`IP_PROT_POS])
          begin
            ip_prot_en_o  <= '1;
            if (ip_6b_n2b_start_i)
              ip_prot_o <= pkt_data_i[`IP_PROT_6B];
            else
              ip_prot_o <= pkt_data_i[`IP_PROT_2B];
          end

//Get IP header length (в двойных словах) 
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    ip_length     <= '0;
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          ip_length <= '0;
        end
      else
        if (ip_en_i)
          if (data_pos[`IP_LEN_POS]) 
            if (ip_6b_n2b_start_i)
              ip_length <= pkt_data_i[`IP_HEAD_LEN_6B];
            else
              ip_length <= pkt_data_i[`IP_HEAD_LEN_2B];


logic ip_head_ok; //адекватность ip заголовка
assign ip_head_ok = (ip_length == 4'd5) && (ip_version == 4'd4);

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
            if(data_pos[`L4_START_6B_POS])
              //Assert if udp or tcp protocol and ipv4 and header length 20 byte
              tcp_udp_en_o <= ip_head_ok & (ip_prot_en_o & tcp_udp_prot_w);
          end
        else //выравнивание по второму байту
          begin
            if(data_pos[`L4_START_2B_POS])
              //Assert if udp or tcp protocol and ipv4 and header length 20 byte
              tcp_udp_en_o <= ip_head_ok & (ip_prot_en_o & tcp_udp_prot_w);
          end

assign tcp_udp_prot_w = (ip_prot_o == `UDP_PROT) || (ip_prot_o == `TCP_PROT);


//Assert l4_en_o: ipv4 + длина заголовка 20 байт
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    ipv4_l4_en_o <= 1'b0;
  else
    if (pkt_en_i)
      if (pkt_eop_o) //на такт позже убираем l4_en_o
        ipv4_l4_en_o <= 1'b0;
      else
        if (ip_6b_n2b_start_i)
          begin
            if(data_pos[`L4_START_6B_POS])
              ipv4_l4_en_o <= ip_head_ok & ip_prot_en_o;
          end
        else //выравнивание по второму байту
          begin
            if(data_pos[`L4_START_2B_POS])
              ipv4_l4_en_o <= ip_head_ok & ip_prot_en_o;
          end

endmodule
