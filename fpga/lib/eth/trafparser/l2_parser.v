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

`include "l2_parser.vh"

module l2_parser #(parameter max_pos_p = 2) (
  input                  clk_i,
  input                  rst_i,
  input                  srst_i,
  input                  en_i,

//Input pkt interface
  input [63:0]           pkt_data_i,
  input [2:0]            pkt_mod_i,
  input                  pkt_eop_i,                           
  input                  pkt_sop_i,                           
  input                  pkt_en_i,                            

//Output pkt interface
  output [63:0]          pkt_data_o,                          
  output [2:0]           pkt_mod_o,
  output                 pkt_eop_o,                           
  output                 pkt_sop_o,                           
  output                 pkt_en_o,                            

  //mac outputs
  output logic [47:0]      macd_o,
  output logic             macd_en_o,
  output logic [47:0]      macs_o,
  output logic             macs_en_o,

  //ethertype outputs
  output logic [15:0]      ethtype_o,     //ethertype field
  output logic             ethtype_en_o,  //enable для ethtype_o

  //vlan0 outputs
  output logic [15:0]      vlan0_vid_o,    //vlan0 vlad ID (+ PCP, CFI bits)
  output logic             vlan0_vid_en_o, //enable for vlan0_vid_o

  //vlan1 outputs
  output logic [15:0]      vlan1_vid_o,    //vlan1 vlad ID (+ PCP, CFI bits)
  output logic             vlan1_vid_en_o, //enable for vlan1_vid_o

  //vlan2 outputs
  output logic [15:0]      vlan2_vid_o,     //vlan2 vlad ID (+ PCP, CFI bits)
  output logic             vlan2_vid_en_o,  //enable for vlan2_vid_o

  output logic [1:0]       vlan_cnt_o,
  
  //mpls enable
  output logic             l25_en_o         //начало уровня 2.5 (а может и сразу 3-го уровня_)

);


logic [max_pos_p-1:0] data_pos; //Input data position

//Big Endian
logic [15:0] ethtype;     
logic        ethtype_en;

logic [15:0] vlan0_vid;     
logic        vlan0_vid_en;
logic [15:0] vlan1_vid;     
logic        vlan1_vid_en;
logic [15:0] vlan2_vid;     
logic        vlan2_vid_en;



assign l25_en_o = ethtype_en; //эти сигналы совпадают
//Position counter (as shift register)
always_ff @(posedge clk_i, posedge rst_i)
  if(rst_i)
    begin 
      data_pos    <= 1;
    end  
  else
    if(pkt_en_i)
      if(pkt_eop_i)
        data_pos <= 1; //по концу пакета 
      else
        data_pos <= {data_pos[max_pos_p-2:0],1'b0};

logic [68:0] data_d1;

logic        pkt_en_d1;

// регистр задержки всех сигналов пакета
always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    data_d1 <= '0;
  else
    if( pkt_en_i )
      data_d1 <= {pkt_mod_i, pkt_sop_i, pkt_eop_i, pkt_data_i};


always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    pkt_en_d1 <= 1'b0;
  else
    pkt_en_d1 <= pkt_en_i;

//назначаем выходные данные
assign {pkt_mod_o, pkt_sop_o, pkt_eop_o, pkt_data_o} = data_d1;
assign pkt_en_o = pkt_en_d1;

//Get destination mac address
always_ff @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      macd_o    <= '0;
      macd_en_o <= '0;
    end
  else
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          macd_o    <= '0;
          macd_en_o <= '0;
        end
      else
        if (data_pos[`MACD_POS])
          begin
            macd_o    <= pkt_data_i[`MACD_BITS_POS];
            macd_en_o <= 1'd1;
          end

//Get source mac address
always_ff @(posedge clk_i, posedge rst_i)
  if (rst_i)
    begin
      macs_o    <= '0;
      macs_en_o <= '0;
    end
  else
    if (pkt_en_i)
      if (pkt_eop_i)
        begin
          macs_o    <= '0;
          macs_en_o <= '0;
        end
      else
        if (data_pos[`MACS_POS_START])
          begin
            macs_o[15:0]    <= pkt_data_i[`MACS_BITS_POS_START];
          end
        else
          if (data_pos[`MACS_POS_END])
            begin
              macs_o[47:16]    <= pkt_data_i[`MACS_BITS_POS_END];
              macs_en_o        <= 1'd1;
            end
            
//Get vlan0
always_ff @(posedge clk_i, posedge rst_i)
  if(rst_i)
    begin
      vlan0_vid     <= '0;
      vlan0_vid_en  <= '0;
    end
  else
    if(pkt_en_i)
      if(pkt_eop_i)
        begin
          vlan0_vid     <= '0;
          vlan0_vid_en  <= '0;
        end
      else
        if(data_pos[`VLAN0_POS]) //находимся на слове, где содержится 
                                   //vlan0 либо ethertype
          begin
            if((pkt_data_i[`VLANTPID0_BITS_POS] == `VLANTPID0) || //обнаружился vlan0
               (pkt_data_i[`VLANTPID0_BITS_POS] == `VLANTPID1))
              begin //запоминаем vlan ID
                vlan0_vid    <= pkt_data_i[`VLANID0_BITS_POS];
                vlan0_vid_en <= 1'b1;
              end
          end

//Get vlan1
always_ff @(posedge clk_i, posedge rst_i)
  if(rst_i)
    begin
      vlan1_vid     <= '0;
      vlan1_vid_en  <= '0;
    end
  else
    if(pkt_en_i)
      if(pkt_eop_i)
        begin
          vlan1_vid     <= '0;
          vlan1_vid_en  <= '0;
        end
      else
        if(data_pos[`VLAN1_POS]) //находимся на слове, где содержится 
                                   //vlan0 либо ethertype
          begin
            if((pkt_data_i[`VLANTPID1_BITS_POS] == `VLANTPID0) || //обнаружился vlan0
               (pkt_data_i[`VLANTPID1_BITS_POS] == `VLANTPID1))
              begin //запоминаем vlan ID
                vlan1_vid    <= pkt_data_i[`VLANID1_BITS_POS];
                vlan1_vid_en <= vlan0_vid_en; //второй vlan возможен
                                                 //только если был первый
              end
          end

//Get vlan2
always_ff @(posedge clk_i, posedge rst_i)
  if(rst_i)
    begin
      vlan2_vid     <= '0;
      vlan2_vid_en  <= '0;
    end
  else
    if(pkt_en_i)
      if(pkt_eop_i)
        begin
          vlan2_vid     <= '0;
          vlan2_vid_en  <= '0;
        end
      else
        if(data_pos[`VLAN2_POS]) //находимся на слове, где содержится 
                                   //vlan0 либо ethertype
          begin
            if((pkt_data_i[`VLANTPID2_BITS_POS] == `VLANTPID0) || //обнаружился vlan2
               (pkt_data_i[`VLANTPID2_BITS_POS] == `VLANTPID1))
              begin //запоминаем vlan ID
                vlan2_vid    <= pkt_data_i[`VLANID2_BITS_POS];
                if((pkt_data_i[`VLANTPID1_BITS_POS] == `VLANTPID0) || //обнаружился vlan1
                   (pkt_data_i[`VLANTPID1_BITS_POS] == `VLANTPID1))
                  vlan2_vid_en <= 1'b1; //третий vlan возможен только если был втророй
              end
          end

//Get ethertype
always_ff @(posedge clk_i, posedge rst_i)
  if(rst_i)
    begin
      ethtype    <= '0;
      ethtype_en <= '0;
    end
  else
    if(pkt_en_i)
      if(pkt_eop_i)
        begin
          ethtype    <= '0;
          ethtype_en <= '0;
        end
      else
        case(1'b1)
          data_pos[`ETHTYPE0_POS]:
            begin
              if((pkt_data_i[`VLANTPID0_BITS_POS] != `VLANTPID0) && //не обнаружился vlan0
                 (pkt_data_i[`VLANTPID0_BITS_POS] != `VLANTPID1))
                begin //запоминаем ethertype
                  ethtype    <= pkt_data_i[`ETHTYPE0_BITS_POS];
                  ethtype_en <= 1'b1;
                end
            end
 
          data_pos[`ETHTYPE1_POS]:
            begin
              //если нет первого vlan и был нулевой, то запоминаем ethertype
              if((pkt_data_i[`VLANTPID1_BITS_POS] != `VLANTPID0) &&
                 (pkt_data_i[`VLANTPID1_BITS_POS] != `VLANTPID1))
                begin
                  if (vlan0_vid_en)
                    begin
                      ethtype    <= pkt_data_i[`ETHTYPE1_BITS_POS];
                      ethtype_en <= 1'd1;
                    end
                end

              //если нет второго vlan и был первый, то запоминаем ethertype
              if((pkt_data_i[`VLANTPID2_BITS_POS] != `VLANTPID0) && //нет vlan2
                 (pkt_data_i[`VLANTPID2_BITS_POS] != `VLANTPID1))
                begin 

                  if((pkt_data_i[`VLANTPID1_BITS_POS] == `VLANTPID0) || //есть vlan1
                     (pkt_data_i[`VLANTPID1_BITS_POS] == `VLANTPID1))

                    if (vlan0_vid_en)
                      begin
                        ethtype    <= pkt_data_i[`ETHTYPE2_BITS_POS];
                        ethtype_en <= 1'd1;
                      end

                end
            end

          data_pos[`ETHTYPE3_POS]:
            begin
              if (vlan2_vid_en)
                begin 
                  ethtype    <= pkt_data_i[`ETHTYPE3_BITS_POS];
                  ethtype_en <= 1'd1;
                end
            end
          default:
            begin
            end
 
        endcase



//Big Endian -> Little Endian
assign ethtype_en_o =   ethtype_en;
assign ethtype_o    = { ethtype[7:0], ethtype[15:8] };

assign vlan0_vid_en_o =   vlan0_vid_en;
assign vlan0_vid_o    = { vlan0_vid[7:0], vlan0_vid[15:8] };

assign vlan1_vid_en_o =   vlan1_vid_en;
assign vlan1_vid_o    = { vlan1_vid[7:0], vlan1_vid[15:8] };

assign vlan2_vid_en_o =   vlan2_vid_en;
assign vlan2_vid_o    = { vlan2_vid[7:0], vlan2_vid[15:8] };

assign vlan_cnt_o     = vlan0_vid_en_o + 
                        vlan1_vid_en_o + 
                        vlan2_vid_en_o;

endmodule
