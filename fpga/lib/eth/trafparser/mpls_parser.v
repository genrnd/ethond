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

`include "mpls_parser.vh"

module mpls_parser #(parameter max_pos_p = 6) (
  input                  clk_i,
  input                  rst_i,
  input                  srst_i,
  input                  en_i,


  input  logic [15:0]    ethtype_i,     //ethertype field

  //нужна информация о наличии mpls меток, чтобы понять где находятся
  //mpls метки
  input                  vlan0_vid_en_i, //enable for vlan0
  input                  vlan1_vid_en_i, //enable for vlan1
  input                  vlan2_vid_en_i, //enable for vlan2

//Input pkt interface
  input [63:0]           pkt_data_i,
  input [2:0]            pkt_mod_i,
  input                  pkt_eop_i,                           
  input                  pkt_sop_i,                           
  input                  pkt_en_i,                            
  
  input                  l25_en_i,
//Output pkt interface
  output [63:0]          pkt_data_o,                         
  output [2:0]           pkt_mod_o,
  output                 pkt_eop_o,                           
  output                 pkt_sop_o,                           
  output                 pkt_en_o,                            
//Laver 3 output enable
  output                 ip_en_o,
  output                 ipv6_en_o,
  output                 ip_6b_n2b_start_o, //1 - ip starts at 6 byte, 
                                            //0 - ip starts at 2 byte of pkt_data_i
  //mpls outputs (max 3 labels)
  output logic [31:0]      mpls0_o,
  output logic             mpls0_en_o,

  output logic [31:0]      mpls1_o,
  output logic             mpls1_en_o,

  output logic [31:0]      mpls2_o,
  output logic             mpls2_en_o,

  output logic [1:0]       mpls_cnt_o
);

logic [68:0]          data_r0;
logic                 mpls_en_w;
logic                 ethtype_ip_en_r0;
logic                 ethtype_ipv6_en_r0;
logic [max_pos_p-1:0] data_pos; //Input data position
logic                 mpls0_bos_r0; //Mpls 0 bottom of stack
logic                 mpls1_bos_r0;
logic                 mpls2_bos_r0;

logic                 pkt_en_d1;

assign ip_en_o = mpls0_bos_r0 | mpls1_bos_r0 | mpls2_bos_r0 | ethtype_ip_en_r0;
assign ipv6_en_o = ~mpls0_bos_r0 & ~mpls1_bos_r0 & ~mpls2_bos_r0 & ethtype_ipv6_en_r0; 
//ipv6_en_o выставляется если не было mpls меток и ethertype == ipv6_ethertype. 
//априори считаем, что если есть mpls метка, то это ipv4
assign ip_6b_n2b_start_o =  ~((mpls0_en_o ^ mpls1_en_o) ^ (mpls2_en_o ^ vlan0_vid_en_i) ^ (vlan1_vid_en_i ^ vlan2_vid_en_i));

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
        if(l25_en_i)   //позиция отсчитывает только слова уровня 2.5
          data_pos <= {data_pos[max_pos_p-2:0],1'b0};

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    begin
      data_r0            <= '0; 
      ethtype_ip_en_r0   <= '0;
      ethtype_ipv6_en_r0 <= '0;
    end
  else
    if( pkt_en_i )
      begin
        data_r0            <= { pkt_mod_i,pkt_sop_i, pkt_eop_i, pkt_data_i };
        ethtype_ip_en_r0   <= ( ( ethtype_i == `IP_TYPE   ) && l25_en_i );
        ethtype_ipv6_en_r0 <= ( ( ethtype_i == `IPV6_TYPE ) && l25_en_i );
      end

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    pkt_en_d1 <= 1'b0;
  else
    pkt_en_d1 <= pkt_en_i;


assign { pkt_mod_o, pkt_sop_o, pkt_eop_o, pkt_data_o } = data_r0; 

assign pkt_en_o = pkt_en_d1;


assign mpls_en_w = (((ethtype_i == `MPLS_TYPE0) || (ethtype_i == `MPLS_TYPE1)) &
                      l25_en_i);


//Get first mpls label
always_ff @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      mpls0_o       <= '0;
      mpls0_en_o    <= '0;
      mpls0_bos_r0  <= '0;
    end
  else
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          mpls0_o       <= '0;
          mpls0_en_o    <= '0;
          mpls0_bos_r0  <= '0;
        end
      else
        begin
          if(data_pos[`MPLS0_1VLAN_3VLAN_POS])
            begin
              if(mpls_en_w & ((vlan0_vid_en_i & vlan1_vid_en_i & vlan2_vid_en_i) ||    //три VLANа
                              (vlan0_vid_en_i & ~vlan1_vid_en_i & ~vlan2_vid_en_i))  ) //или один VLAN
                begin
                  mpls0_o    <= {pkt_data_i[`MPLS0_1VLAN_3VLAN_B3],pkt_data_i[`MPLS0_1VLAN_3VLAN_B2], 
                                 pkt_data_i[`MPLS0_1VLAN_3VLAN_B1],pkt_data_i[`MPLS0_1VLAN_3VLAN_B0]};
                  //Enable для mpls0 включается всегда, если есть метка
                  mpls0_en_o <= 1'b1;
                  //BOS0 определяется по спец. битику в MPLS0
                  mpls0_bos_r0 <= pkt_data_i[`MPLS0_1VLAN_3VLAN_BOS_BIT];
                end
             end

          if(data_pos[`MPLS0_NOVLAN_2VLAN_POS])
            begin
              if( mpls_en_w & (~(vlan0_vid_en_i | vlan1_vid_en_i | vlan2_vid_en_i) || //VLANов нет
                                (vlan0_vid_en_i & vlan1_vid_en_i & ~vlan2_vid_en_i)) ) //или два VLANа
                begin
                  mpls0_o       <= {data_r0[`MPLS0_NOVLAN_2VLAN_B3], data_r0[`MPLS0_NOVLAN_2VLAN_B2],
                                    pkt_data_i[`MPLS0_NOVLAN_2VLAN_B1], pkt_data_i[`MPLS0_NOVLAN_2VLAN_B0]};
                  //Enable для mpls0 включается всегда, если есть метка
                  mpls0_en_o    <= '1;
                  //BOS0 определяется по спец. битику в MPLS0
                  mpls0_bos_r0 <= pkt_data_i[`MPLS0_NOVLAN_2VLAN_BOS_BIT];
                end
            end
        end

//Get second mpls label
always_ff @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      mpls1_o       <= '0;
      mpls1_en_o    <= '0;
      mpls1_bos_r0  <= '0;
    end
  else
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          mpls1_o       <= '0;
          mpls1_en_o    <= '0;
          mpls1_bos_r0  <= '0;
        end
      else
        if (mpls_en_w & data_pos[`MPLS1_POS])
          case ({vlan2_vid_en_i, vlan1_vid_en_i, vlan0_vid_en_i})
            3'b111, 3'b001://3 VLAN, 1 VLAN
              begin //эту ветку ПРОВЕРИЛИ
                mpls1_o       <= {data_r0[`MPLS1_1VLAN_3VLAN_B3], data_r0[`MPLS1_1VLAN_3VLAN_B2],
                                  pkt_data_i[`MPLS1_1VLAN_3VLAN_B1], pkt_data_i[`MPLS1_1VLAN_3VLAN_B0]};
                //Enable для mpls1 устанавлявается если в mpls0 не было BOS и была сама метка mpls0 (mpls_en_w)
                mpls1_en_o    <= ~mpls0_o[`MPLS0_BOS_BIT];
                //BOS1 устанавливается если установлен спец. бит в mpls1, но не было BOS в mpls0 и была метка mpls0 (mpls_en_w)
                mpls1_bos_r0 <= pkt_data_i[`MPLS1_1VLAN_3VLAN_BOS_BIT] & ~mpls0_o[`MPLS0_BOS_BIT];
              end
            3'b000, 3'b011://No VLAN, 2 VLAN
              begin
                mpls1_o    <= {pkt_data_i[`MPLS1_NOVLAN_2VLAN_B3],pkt_data_i[`MPLS1_NOVLAN_2VLAN_B2], 
                               pkt_data_i[`MPLS1_NOVLAN_2VLAN_B1],pkt_data_i[`MPLS1_NOVLAN_2VLAN_B0]};
                //Enable для mpls1 устанавлявается если в mpls0 не было BOS и была сама метка mpls0
                mpls1_en_o <= ~pkt_data_i[`MPLS0_NOVLAN_2VLAN_BOS_BIT];
                //BOS1 устанавливается если установлен спец. бит в mpls1, но не было BOS в mpls0
                mpls1_bos_r0 <= pkt_data_i[`MPLS1_NOVLAN_2VLAN_BOS_BIT] & ~pkt_data_i[`MPLS0_NOVLAN_2VLAN_BOS_BIT];
              end
          endcase

//Get third mpls label
always_ff @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      mpls2_o       <= '0;
      mpls2_en_o    <= '0;
      mpls2_bos_r0  <= '0;
    end
  else
    if (pkt_en_i)
      begin
        if (pkt_eop_i)
          begin
            mpls2_o       <= '0;
            mpls2_en_o    <= '0;
            mpls2_bos_r0  <= '0;
          end
        else
          begin
            if (data_pos[`MPLS2_1VLAN_3VLAN_POS])
              begin
                if(mpls_en_w & ((vlan0_vid_en_i & vlan1_vid_en_i & vlan2_vid_en_i) ||    //три VLANа
                                (vlan0_vid_en_i & ~vlan1_vid_en_i & ~vlan2_vid_en_i))  ) //или один VLAN
                  begin
                    mpls2_o    <= {pkt_data_i[`MPLS2_1VLAN_3VLAN_B3],pkt_data_i[`MPLS2_1VLAN_3VLAN_B2], 
                                   pkt_data_i[`MPLS2_1VLAN_3VLAN_B1],pkt_data_i[`MPLS2_1VLAN_3VLAN_B0]};

                    //Enable для mpls2 устанавливается только если не было BOS в mpls1 и была метка mpls1
                    mpls2_en_o <= ~pkt_data_i[`MPLS1_1VLAN_3VLAN_BOS_BIT] & ~mpls0_o[`MPLS0_BOS_BIT];
                    //Looking for bottom of stack in MPLS2 if doesn't have it in MPLS1
                    mpls2_bos_r0  <= pkt_data_i[`MPLS2_1VLAN_3VLAN_BOS_BIT]  & ~pkt_data_i[`MPLS1_1VLAN_3VLAN_BOS_BIT]
                                                                             & ~mpls0_o[`MPLS0_BOS_BIT];
                  end
              end

            if (data_pos[`MPLS2_NOVLAN_2VLAN_POS])
              begin
                if( mpls_en_w & (~(vlan0_vid_en_i | vlan1_vid_en_i | vlan2_vid_en_i) || //VLANов нет
                                  (vlan0_vid_en_i & vlan1_vid_en_i & ~vlan2_vid_en_i)) ) //или два VLANа
                  begin
                    mpls2_o       <= {data_r0[`MPLS2_NOVLAN_2VLAN_B3], data_r0[`MPLS2_NOVLAN_2VLAN_B2],
                                      pkt_data_i[`MPLS2_NOVLAN_2VLAN_B1], pkt_data_i[`MPLS2_NOVLAN_2VLAN_B0]};
                    //Assert enable if MPLS1 doesn't have bottom of stack
                    mpls2_en_o    <= ~mpls1_o[`MPLS1_BOS_BIT] & mpls1_en_o;
                    //Looking for bottom of stack in MPLS2 if doesn't have it in MPLS1
                    mpls2_bos_r0  <= pkt_data_i[`MPLS2_NOVLAN_2VLAN_BOS_BIT] /*BOS OF mpls2*/ & ~mpls1_o[`MPLS1_BOS_BIT] & mpls1_en_o;
                  end
              end
          end
      end

assign  mpls_cnt_o = mpls0_en_o + mpls1_en_o + mpls2_en_o;

endmodule
