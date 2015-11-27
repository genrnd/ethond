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

module conv_1G_rx_fifo(

  input         clk_mac_i,    //Clk_MAC (по которому пишем в fifo)
  input         clk_mac_en_i, 
  input         rst_i,        //Reset
  input         clk_sys_i,   //Clk_SYS (по которому читаем с fifo)

  // интерфейс от MAC_rx_ctrl
  input [7:0]   fifo_wr_data_i,
  input         fifo_wr_data_en_i,
  input         fifo_wr_data_err_i,
  input         fifo_wr_data_end_i,
  input         frame_crc_err_i,
  output        fifo_full_o,

  // read req из arb
  input         fifo_rd_req_i,
  
  output [63:0] pkt_data_o,
  output        pkt_sop_o,
  output        pkt_eop_o,
  output [2:0]  pkt_mod_o,
  output        frame_crc_err_o,

  output        pkt_avail_o

);

enum int unsigned { IDLE,
                    ACCUM,
                    WRITE,
                    WRITE_EOP,
                    WRITE_EOP_SW,
                    DROP_FRAG    
                  } state, next_state;

logic        sop_fifo;

logic        eop_fifo;
logic [2:0]  mod_fifo;
logic [63:0] pkt_fifo_data;

logic [2:0] counter;

logic [1:0] sop_logic;

logic wr_req;

//FSM
always_ff @( posedge clk_mac_i or posedge rst_i ) 
  if( rst_i )
    state <= IDLE;
  else
    if( clk_mac_en_i )
      state <= next_state;

always_comb
begin
  case(state)
    IDLE:
      if(fifo_wr_data_en_i)
        next_state = ACCUM;
      else
        next_state = IDLE;

    ACCUM:
      if(fifo_wr_data_err_i || fifo_wr_data_end_i) //пришел конец пакета
        begin
          if(sop_logic[0] == 1'b1)
           begin
             next_state = DROP_FRAG; //если пришел конец пакета до того момента, как записали sop
           end                       //вообще не пишем ничего в фифо, не уверен, что это правильно, но
          else                       //в 10G rx_enqueue именно так делается.
            begin                    //TODO: проверить на пакетах 8-16
              if(counter < 5)
                next_state = WRITE_EOP; //большое слово что у нас есть записываем в fifo, остальное - мусор
              else
                next_state = WRITE_EOP_SW; //если уже больше насчитал счетчик, то записываем, то, что накопилось
            end
        end
      else
        if(fifo_wr_data_en_i)
          begin
            if(counter == 4 && (sop_logic != 2'b01))//4
              next_state = WRITE; //записываем
            else
              next_state = ACCUM;
          end
        else
          next_state = ACCUM;
   
   WRITE: //на четвертый такт записываем, что у нас было
     if(fifo_wr_data_err_i || fifo_wr_data_end_i)
       begin
         next_state = WRITE_EOP_SW;
       end
     else
       next_state = ACCUM;

   WRITE_EOP: //записываем слово в fifo, выставляем eop
     next_state = IDLE;
   
   WRITE_EOP_SW: //записываем небольшой кусок
     next_state = IDLE;

   DROP_FRAG:  //переходим в idle, ничего никуда не пишем
     next_state = IDLE;
    endcase
end

//FIXME: похорошему, надо добавить, если у нас заполнилось фифо, записывать eop и не начинать
//запись в фифо, пока не будет там usedw меньше какого-то

//TODO: проверить адекватность работы модуля (да и всего приёма) в tb при runt 
//или фрагментах пакета - уже на этом обожглись - если на приеме был пакет меньше 8 байт
//то неписался sop, а писалось много eop

//считаем сколько слов 8битных набралось, когда наберется 8 - запишем в fifo
always_ff @(posedge clk_mac_i or posedge rst_i)
  if ( rst_i )
    counter <= 0;
  else
    if( clk_mac_en_i )
      begin
        if( fifo_wr_data_en_i )
          begin
            if( ( next_state == ACCUM ) || ( state == ACCUM ) || ( next_state == WRITE ) )
              counter <= counter + 1'd1;
            else
              counter <= 0;
          end
        else
          if( state == IDLE )
            counter <= 0;
      end

always_ff @( posedge clk_mac_i or posedge rst_i )
  if( rst_i )
    pkt_fifo_data <= 0;
  else
    if( clk_mac_en_i ) 
      begin
        if( ( next_state != IDLE ) && fifo_wr_data_en_i )
          begin
            case( counter )
              'd7:
                pkt_fifo_data[63:56] <= fifo_wr_data_i;
              'd6:
                pkt_fifo_data[55:48] <= fifo_wr_data_i;
              'd5:
                pkt_fifo_data[47:40] <= fifo_wr_data_i;
              'd4:
                pkt_fifo_data[39:32] <= fifo_wr_data_i;
              'd3:
                pkt_fifo_data[31:24] <= fifo_wr_data_i;
              'd2:
                pkt_fifo_data[23:16] <= fifo_wr_data_i;
              'd1:
                pkt_fifo_data[15:8]  <= fifo_wr_data_i;
              'd0:
                pkt_fifo_data[7:0]   <= fifo_wr_data_i;
            endcase
          end
      end

logic [63:0] pkt_fifo_tmp_data;

//пересохраняем что накопили в tmp
always_ff @( posedge clk_mac_i or posedge rst_i )
  if( rst_i )
    pkt_fifo_tmp_data <= 0;
  else
    if( clk_mac_en_i )
      begin
        if( ( counter == 0 ) && ( state == ACCUM ) )
          pkt_fifo_tmp_data <= pkt_fifo_data;
      end


always_ff @(posedge clk_mac_i or posedge rst_i)
  if( rst_i )
    wr_req <= 0;
  else
    if( clk_mac_en_i )
      begin
        if( ( next_state == WRITE ) || ( next_state == WRITE_EOP ) || ( next_state == WRITE_EOP_SW ) )
          wr_req <= 1;
        else
          wr_req <= 0;
      end
    else //сделано для того, что бы не держался wr_req 2 такта при 10/100 (когда clk_mac_en управляет)
      wr_req <= 0;

//нужно для того, что бы мы записывали первое 64 битное слово не сразу, что бы аккумулятор хотя бы наполнился до 8
always_ff @(posedge clk_mac_i or posedge rst_i)
  if( rst_i )
    sop_logic <= '0;
  else
    if( wr_req )
      sop_logic <= '0;
    else
      if( state == IDLE )
        sop_logic[0] <= 1'b1;
      else
        if( ( counter == 0 ) && ( state == ACCUM ) )
          sop_logic[1] <= 1'b1;

always_ff @( posedge clk_mac_i or posedge rst_i )
  if( rst_i )
    sop_fifo <= 1'b0;
  else
    if( clk_mac_en_i )
      begin
        if( ( next_state == WRITE ) && ( sop_logic[0] == 1'b1 ) )
          sop_fifo <= 1'b1;
        else
          sop_fifo <= 1'b0;
      end

always_ff @( posedge clk_mac_i or posedge rst_i )
  if( rst_i )
    eop_fifo <= 1'b0;
  else
    if( clk_mac_en_i )
      if( ( next_state == WRITE_EOP ) || ( next_state == WRITE_EOP_SW ) )
        eop_fifo <= 1'b1;
      else
        eop_fifo <= 1'b0;

always_ff @( posedge clk_mac_i or posedge rst_i )
  if( rst_i )
      mod_fifo <= 0;
  else
    if( clk_mac_en_i )
      if( next_state == WRITE_EOP )
        mod_fifo <= counter - 3'd4;
      else
        if( next_state == WRITE_EOP_SW )
          mod_fifo <= counter - 3'd4;
        else
          if( next_state == IDLE )
            mod_fifo <= 0;

//пока на comb_logic
logic [63:0] data_to_write;

always_comb
  if( state == WRITE_EOP_SW )
    data_to_write = pkt_fifo_data;
  else
    data_to_write = pkt_fifo_tmp_data;

logic fifo_wr_req;
logic fifo_rd_empty;
logic fifo_almost_full;

typedef struct packed {
  logic [63:0] pkt_data;
  logic [2:0]  mod;
  logic        sop;
  logic        eop;
  logic        crc_err;
} fifo_data_t;

fifo_data_t fifo_wr_data;
fifo_data_t fifo_rd_data;

assign fifo_wr_data.pkt_data = data_to_write;
assign fifo_wr_data.mod      = mod_fifo;
assign fifo_wr_data.sop      = sop_fifo;
assign fifo_wr_data.eop      = eop_fifo;
assign fifo_wr_data.crc_err  = frame_crc_err_i;

assign fifo_full_o = fifo_almost_full;
assign pkt_avail_o = !fifo_rd_empty;

assign fifo_wr_req = wr_req;

assign pkt_data_o      = fifo_rd_data.pkt_data; 
assign pkt_sop_o       = fifo_rd_data.sop; 
assign pkt_eop_o       = fifo_rd_data.eop;
assign pkt_mod_o       = fifo_rd_data.mod; 
assign frame_crc_err_o = fifo_rd_data.crc_err; 

stat_fifo_generic #( 
  
  // не надо слишком большой, т.к. не будем буферизовать весь пакет
  .AWIDTH                                 ( 5                     ), 
  .DWIDTH                                 ( $bits( fifo_wr_data ) ),
  .DUAL_CLOCK                             ( 1                     ),
  .SHOWAHEAD                              ( "ON"                  ),
  
  .SAFE_WORDS                             ( 10                    ),

  .LPM_HINT                               ( "RAM_BLOCK_TYPE=AUTO" )
) fifo (
  
  .rst_i                                  ( rst_i             ),
    
  .wr_clk_i                               ( clk_mac_i         ),
  .wr_req_i                               ( fifo_wr_req       ),
  .wr_data_i                              ( fifo_wr_data      ),

  .rd_clk_i                               ( clk_sys_i         ),
  .rd_req_i                               ( fifo_rd_req_i     ),
  .rd_data_o                              ( fifo_rd_data      ),
    
  .rd_empty_o                             ( fifo_rd_empty     ),
  .wr_almost_full_o                       ( fifo_almost_full  )

);

endmodule
