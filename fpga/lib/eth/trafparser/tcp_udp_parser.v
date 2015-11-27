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

`include "tcp_udp_parser.vh"

module tcp_udp_parser #(parameter max_pos_p = 5)(
  input                  clk_i,
  input                  rst_i,
  input                  tcp_en_i,
  input                  tcp_udp_ipv4_en_i,
  input                  tcp_udp_ipv6_en_i,
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
  output logic [2:0]     pkt_mod_o,
  output logic           pkt_eop_o,                           
  output logic           pkt_sop_o,                           
  output logic           pkt_en_o,                            

//Status signal
  output logic [15:0]    port_src_o,
  output logic           port_src_en_o,

  output logic [15:0]    port_dst_o,
  output logic           port_dst_en_o,
  
  output logic [8:0]     tcp_flags_o,
  output logic           tcp_flags_en_o
);


logic    tcp_udp_6b_n2b_start; //с какого слова начинается tcp/udp header
logic    tcp_udp_en;

logic [max_pos_p-1:0] data_pos; //Input data position
logic [68:0]          data_r0;
logic                 pkt_en_d1;


assign tcp_udp_6b_n2b_start = (ip_6b_n2b_start_i & tcp_udp_ipv6_en_i) || (~ip_6b_n2b_start_i & tcp_udp_ipv4_en_i);
assign tcp_udp_en = tcp_udp_ipv4_en_i || tcp_udp_ipv6_en_i;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    data_r0 <= '0;
  else
    if( pkt_en_i )
      data_r0 <= {pkt_mod_i, pkt_sop_i, pkt_eop_i, pkt_data_i};

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
        if(tcp_udp_en)   //позиция отсчитывает только слова уровня 2.5
          data_pos <= {data_pos[max_pos_p-2:0],1'b0};

//Get source port
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      port_src_o     <= '0;
      port_src_en_o  <= 1'd0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          port_src_o <= '0;
          port_src_en_o  <= 1'd0;
        end
      else
            if (data_pos[`SRCPORT_POS] & tcp_udp_en) //src port находится в нулевом слове
              begin
                if (tcp_udp_6b_n2b_start)
                  begin
                    port_src_o     <= {pkt_data_i[`SRCPORT_T6B_B1], pkt_data_i[`SRCPORT_T6B_B0]};
                    port_src_en_o  <= 1'd1;
                  end
               else //not tcp_udp_6b_n2b_start
                  begin
                    port_src_o <= {pkt_data_i[`SRCPORT_T2B_B1], pkt_data_i[`SRCPORT_T2B_B0]};
                    port_src_en_o  <= 1'd1;
                  end
              end

//Get dst port
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      port_dst_o     <= '0;
      port_dst_en_o  <= 1'd0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          port_dst_o <= '0;
          port_dst_en_o  <= 1'd0;
        end
      else
          if (tcp_udp_6b_n2b_start)
            begin
              if (data_pos[`DSTPORT_T6B_POS] & tcp_udp_en) 
                begin
                  port_dst_o     <= {pkt_data_i[`DSTPORT_T6B_B1], pkt_data_i[`DSTPORT_T6B_B0]};
                  port_dst_en_o  <= 1'd1;
                end
            end 
          else 
            begin
              if (data_pos[`DSTPORT_T2B_POS] & tcp_udp_en) 
                begin
                  port_dst_o <= {pkt_data_i[`DSTPORT_T2B_B1], pkt_data_i[`DSTPORT_T2B_B0]};
                  port_dst_en_o  <= 1'd1;
                end
            end

//Get tcp_flags
always @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      tcp_flags_o     <= '0;
      tcp_flags_en_o  <= 1'd0;
    end
  else 
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          tcp_flags_o <= '0;
          tcp_flags_en_o  <= 1'd0;
        end
      else
          if (tcp_udp_6b_n2b_start)
            begin
              if (data_pos[`TCPFLAGS_T6B_POS] & tcp_en_i) 
                begin
                  tcp_flags_o     <= {pkt_data_i[`TCPFLAGS_T6B_B1], pkt_data_i[`TCPFLAGS_T6B_B0]};
                  tcp_flags_en_o  <= 1'd1;
                end
            end 
          else 
            begin
              if (data_pos[`TCPFLAGS_T2B_POS] & tcp_en_i) 
                begin
                  tcp_flags_o <= {pkt_data_i[`TCPFLAGS_T2B_B1], pkt_data_i[`TCPFLAGS_T2B_B0]};
                  tcp_flags_en_o  <= 1'd1;
                end
            end
endmodule
