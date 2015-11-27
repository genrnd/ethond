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

module conv_1G_tx_ctrl(

  input                rst_i,
  input                clk_i,
  input                clk_en_i,
  input                Clk_user,

    //PHY interface
  output logic   [7:0] TxD,
  output logic         TxEn,   

    //CRC_gen Interface 
  output logic         CRC_init,
  output logic   [7:0] Frame_data,
  output logic         Data_en,
  output logic         CRC_rd,
  input                CRC_end,
  input         [7:0]  CRC_out,

  input        [63:0]  pkt_tx_data_i, 
  input         [2:0]  pkt_tx_mod_i,
  input                pkt_tx_sop_i,
  input                pkt_tx_eop_i,
  input                pkt_tx_val_i,

  output               tx_fifo_full_o
);
parameter REDUCED_FIFO = 0; 

// сколько слов надо накопить перед тем, как мы считаем, что надо
// начать отправлять данные на gmii
// 1 - используется сигнал fifo_empty
// 2 - всё остальное - используется количество слов

// по умолчанию ставим равное двум, а не одному для дополнительной перестраховки:
// когда в пакет вставялется паттерн bert'a, то на формирование одного слова
// тратится четыре такта: скорость записи получается равна скорости чтения,
// и чтобы всегда были в fifo были слова для чтения, то делаем здесь на одно
// слово больше, что бы иметь всегда в запасе одно слово
parameter READ_USED_WORDS_FOR_TX_DATA_READY = 2;

// для проекта mx используется уменьшенная фифошка 
// ( на 256 слов ) на передачу, т.к. нет смысла 
// в большой ( по мере чтения из этой фифо мы будем дописывать
// пакет, а если фифо заполнено, то арбитр, который пишет сюда, будет 
// ожидать когда она освободится )

// для остальных ( etx + 1 ) - большая фифошка на пакет 9.6К
// по умолчанию

// в проекте etn:
// в зависимости от фифо переопределяем параметры фифошки
// делаем специально такое маленькое количество слов, чтобы как можно
// раньше выставить tx_full и передачу пакета остановить. это делается для
// того, чтобы мы вставили временную метку как можно ближе к реальной отправке
// пакета наружу
localparam USED_WORDS_WIDTH       = REDUCED_FIFO ? 3 : 11;   
localparam FIFO_NUM_WORDS         = REDUCED_FIFO ? 8 : 2048;
localparam FIFO_ALMOST_FULL_WORDS = REDUCED_FIFO ? 4 : 2038; // нижняя граница сигнала tx_fifo_full

enum logic [5:0] { IFG      = 6'd1,
                   PREAMBLE = 6'd2,
                   SFD      = 6'd4,
                   DATA     = 6'd8,
                   PAD      = 6'd16, //добивание нулями, если пакет <64
                   FCS      = 6'd32
                   } state, next_state;

logic [3:0]  ifg_counter;
logic [3:0]  preamb_counter;
logic [7:0]  pkt_counter;

logic [7:0]  tx_data_tmp;
logic        tx_en_tmp;
logic [7:0]  last_byte;

logic        read_req;
logic [2:0]  byte_counter;
logic        end_frame;

logic        fifo_empty;
logic        fifo_rd_full;
logic        fifo_full;

logic [63:0] pkt_fifo_data; 
logic [2:0]  pkt_fifo_mod;
logic        pkt_fifo_sop;
logic        pkt_fifo_eop;
logic        pkt_fifo_val;

logic [USED_WORDS_WIDTH-1:0] rd_used_words;
logic [USED_WORDS_WIDTH-1:0] wr_used_words;

logic                        tx_data_ready;

always_comb
  begin
    if( READ_USED_WORDS_FOR_TX_DATA_READY == 1 )
      tx_data_ready = !fifo_empty;
    else
      tx_data_ready = ( fifo_rd_full ) || ( rd_used_words >= READ_USED_WORDS_FOR_TX_DATA_READY ); 
  end

// FSM
always_ff @(posedge clk_i or posedge rst_i)
begin
  if(rst_i)
    state <= IFG;
  else
    if(clk_en_i)
      state <= next_state;
end

always_comb
begin
 case(state)
   IFG: //начинаем слать чуть быстрее если в фифо много слов                   
     if( ( ifg_counter == 10 ) && ( rd_used_words > 10 ) && tx_data_ready )
       next_state = PREAMBLE; 
     else  
       if( ( ifg_counter > 10 ) && tx_data_ready )
         next_state = PREAMBLE;
       else
         next_state = IFG;
   PREAMBLE:
     if(preamb_counter < 6)
       next_state = PREAMBLE;
     else
       next_state = SFD;
   SFD:
     next_state = DATA;
   DATA:
     if(end_frame & pkt_counter < 59)
       next_state = PAD;
     else
       if(end_frame)
         next_state = FCS;
       else
         next_state = DATA;
   PAD:
     if(pkt_counter < 59)
       next_state = PAD;
     else
       next_state = FCS;
   FCS:
     if(CRC_end)
       next_state = IFG;
     else
       next_state = FCS;
  endcase
end

always_ff @(posedge clk_i or posedge rst_i)
begin
  if(rst_i)
    ifg_counter <= 0;
  else
    if(clk_en_i)
      if(state == IFG)
        begin
          if(ifg_counter < 12)
            ifg_counter <= ifg_counter + 1'd1;
        end
      else
        ifg_counter <= 0;
end

always_ff @(posedge clk_i or posedge rst_i)
begin
  if(rst_i)
    preamb_counter <= 0;
  else
    if(clk_en_i)
      if(state == IFG)
        preamb_counter <= 0;
      else
        if(state == PREAMBLE & preamb_counter < 6)
          preamb_counter <= preamb_counter + 1'd1;
end

always_ff @(posedge clk_i or posedge rst_i)
begin
  if(rst_i)
    pkt_counter <= 0;
  else
    if(clk_en_i)
      if(state == IFG)
        pkt_counter <= 0;
      else
        if((state == DATA || state == PAD) & pkt_counter != 8'hFF) //от перекрутки 
          pkt_counter <= pkt_counter + 1'd1;
end

//CRC related

assign CRC_init   = ( state == SFD );
assign Frame_data = tx_data_tmp;
assign Data_en    = ( state == DATA ) || ( state == PAD );
assign CRC_rd     = ( state == FCS );
assign tx_en_tmp  = ( state == PREAMBLE ) || ( state == SFD ) || ( state == DATA ) || ( state == FCS ) || ( state == PAD );

always @(posedge clk_i or posedge rst_i)
begin
  if(rst_i)
    begin
      TxD  <= 0;
      TxEn <= 0;
    end
  else
    if(clk_en_i)
      begin
        TxD  <= tx_data_tmp;
        TxEn <= tx_en_tmp;
      end
end

always_comb 
begin
//  if(clk_en_i)
    case(state)
      IFG:
        tx_data_tmp = 8'h07;
      PREAMBLE:
        tx_data_tmp = 8'h55;
      SFD:
        tx_data_tmp = 8'hd5;
      DATA:
        case(byte_counter)
          8'd0:
            tx_data_tmp = pkt_fifo_data[7:0];
          8'd1:
            tx_data_tmp = pkt_fifo_data[15:8];
          8'd2:
            tx_data_tmp = pkt_fifo_data[23:16];
          8'd3:
            tx_data_tmp = pkt_fifo_data[31:24];
          8'd4:
            tx_data_tmp = pkt_fifo_data[39:32];
          8'd5:
            tx_data_tmp = pkt_fifo_data[47:40];
          8'd6:
            tx_data_tmp = pkt_fifo_data[55:48];
          8'd7:
            //tx_data_tmp = pkt_fifo_data[63:56];
            tx_data_tmp   = last_byte;
        endcase
      PAD:
        tx_data_tmp = 8'h00;
      FCS:
        tx_data_tmp = CRC_out;
      default:
        tx_data_tmp = 0;
    endcase
//  else
//    tx_data_tmp = tx_data_tmp;
end

always_ff @(posedge clk_i or posedge rst_i)
begin
  if(rst_i)
    last_byte <= 0;
  else
    if(clk_en_i)
      begin
        if(byte_counter == 0)
          last_byte <= pkt_fifo_data[63:56];
      end
end

always_ff @(posedge clk_i or posedge rst_i)
begin
  if(rst_i)
    byte_counter <= 0;
  else
    if(clk_en_i)
      begin
        if(state == IFG)
          byte_counter <= 0;
        else
          if(state == DATA)
            byte_counter <= byte_counter + 1'd1;
      end
end

always_ff @(posedge clk_i or posedge rst_i)
begin
  if(rst_i)
    read_req <= 0;
  else
    if(clk_en_i)
      begin
        if(next_state == SFD)
          read_req <= 1;
        else
          if(state == DATA & byte_counter == 6 & ~pkt_fifo_eop) //?
            read_req <= 1;
          else
            read_req <= 0;
      end
   else
     read_req <= 0;
end

// overkill for eop and mii
logic read_req_dl;
always_ff @(posedge clk_i or posedge rst_i)
begin
  if(rst_i)
    read_req_dl <= 0;
  else
    read_req_dl <= read_req;
end

always_comb
begin
  if(pkt_fifo_eop & state == DATA)
    if(pkt_fifo_mod == 0)
      if(byte_counter == 7 & ~(read_req_dl))
        end_frame = 1;
      else
        end_frame = 0;
    else
      if(byte_counter == (pkt_fifo_mod-1))
        end_frame = 1;
      else
        end_frame = 0;
  else
    end_frame = 0;
end

// замечено, что в mx, этот сигнал, возможно, занижает частоту 156.25,
// которая используется здесь как Clk_user ( wr_clk ).
// TODO: возможно защелкивать сигнал по регистру
assign tx_fifo_full_o = ( wr_used_words >= FIFO_ALMOST_FULL_WORDS ) || fifo_full; 

logic fifo_wr_req;

assign fifo_wr_req = pkt_tx_val_i && ( !tx_fifo_full_o );

tx_64b_fifo tx_64b_fifo (
.aclr                                   (   rst_i                         ),
.data                                   ( { pkt_tx_eop_i, pkt_tx_sop_i, 
                                            pkt_tx_mod_i, pkt_tx_data_i } ),
.rdclk                                  (   clk_i                         ),
.rdreq                                  (   read_req                      ),
.wrclk                                  (   Clk_user                      ),
.wrreq                                  (   fifo_wr_req                   ),
.q                                      ( { pkt_fifo_eop, pkt_fifo_sop, 
                                            pkt_fifo_mod, pkt_fifo_data } ),
.rdempty                                (   fifo_empty                    ),
.rdfull                                 (   fifo_rd_full                  ),
.wrempty                                (                                 ),
.wrfull                                 (   fifo_full                     ),
.rdusedw                                (   rd_used_words                 ),
.wrusedw                                (   wr_used_words                 )
);
defparam tx_64b_fifo.USED_WORDS_WIDTH = USED_WORDS_WIDTH;
defparam tx_64b_fifo.NUM_WORDS        = FIFO_NUM_WORDS;


// synthesis translate_off

// не надо читать из пустой фифошки
assert property(
  @( posedge clk_i )
   ( ( read_req && fifo_empty ) == 1'b0 )
);

// synthesis translate_on
endmodule
