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
 Арбитр для считывания пакета из фифошки и передачи далее
*/
module conv_1G_rx_arb(
  input                clk_i,
  input                rst_i,

  input                pkt_avail_i,

  input [63:0]         pkt_data_i,
  input                pkt_sop_i,
  input                pkt_eop_i,
  input [2:0]          pkt_mod_i,

  input                frame_crc_err_i,

  output               fifo_rd_req_o,

  input                tr_en_fifo_full_i, 
  output logic [63:0]  pkt_fifo_data_o,
  output logic [7:0]   pkt_fifo_status_o,
  output logic [2:0]   pkt_fifo_error_o,
  output logic [15:0]  pkt_len_o,
  output logic         pkt_fifo_val_o
);

enum int unsigned { IDLE_S,
                    READ_S,
                    DROP_S,
                    ERR_END_S
                  } state, next_state;

logic watchdog_failed;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    state <= IDLE_S;
  else
    state <= next_state;

always_comb
  begin
    next_state = state;

    case( state )

      IDLE_S:
        begin
          // дожидаемся данных и неполноты фифошки
          if( pkt_avail_i && ( !tr_en_fifo_full_i ) )
            begin
              // если есть SOP и нет EOP, то начинаем вычитывать
              // если есть SOP и EOP, то какой-то кусок пришел,
              // и лучше его тоже дропнуть...
              if( pkt_sop_i && ( !pkt_eop_i ) )
                next_state = READ_S;
              else
                // пришел кусок, дропаем 
                next_state = DROP_S;
            end
        end

      READ_S:
        begin
          if( pkt_avail_i )
            begin
              // в нам снова пришел SOP,
              // значит не словили EOP от предыдущего пакета
              if( pkt_sop_i )
                next_state = ERR_END_S;
              else
                // к нам пришел EOP, всё ок,
                // заканчиваем пакет корректно
                if( pkt_eop_i )
                  next_state = IDLE_S;
                else
                  // у нас переполнилась фифошка, заканчиваем передачу пакета.
                  // форсируем ошибку.

                  // приоритет у этой ветки ниже, т.к. в верхних ветках
                  // (как и в этой тоже) будет происходить запись
                  // в фифошку в любом случае, поэтому нам можно и не проверять
                  // заполнена она или нет.

                  // NOTE: фифошка, разумеется должна выставлять сигнал по almost full
                  // что бы иметь возможность еще одно слово дописать
                  if( tr_en_fifo_full_i )
                    next_state = ERR_END_S;
                  else
                    // продолжаем вычитывать пакет
                    next_state = READ_S;
            end
          else
            // сработал watchdog - слишком долго находимся в этом состоянии
            if( watchdog_failed )
              next_state = ERR_END_S; 
        end
      
      ERR_END_S:
        begin
          next_state = DROP_S;
        end
      
      // дочитываем (либо ждем) начала следующего пакета
      DROP_S:
        begin
          if( pkt_avail_i )
            begin
              // о, пришел новый пакет!
              // переходим в IDLE_S, что бы там выполнить 
              // небольшие проверки и корректно начать читать пакет
              if( pkt_sop_i )
                next_state = IDLE_S;
            end
        end

      default:
        begin
          next_state = IDLE_S;
        end
    endcase
  end

assign fifo_rd_req_o = ( pkt_avail_i ) && ( ( ( state == IDLE_S ) && ( ( next_state == READ_S ) || ( next_state == DROP_S ) ) ) ||
                                            ( ( state == READ_S ) && ( ( next_state == IDLE_S ) || ( next_state == READ_S ) ) ) ||
                                            ( ( state == DROP_S ) && ( ( next_state == DROP_S )                             ) ) );  

logic force_eop;                                                  

// форсим eop, если принудительно по каким-то причинам заканчиваем пакет
assign force_eop       = ( state == ERR_END_S );
assign pkt_fifo_data_o = pkt_data_i;

always_comb
  begin
    pkt_fifo_status_o = '0;
    pkt_fifo_error_o  = '0;


    if( pkt_fifo_val_o )
      begin

        // start of packet
        // корректный SOP может быть только тогда когда мы из IDLE переходим в READ
        // поэтому зануляем в остальном случае
        pkt_fifo_status_o[7] = ( ( state == IDLE_S ) && ( next_state == READ_S ) ) ? ( pkt_sop_i ) : ( 1'b0 );
        
        if( force_eop || pkt_eop_i )
          begin
            pkt_fifo_status_o[2:0]  = force_eop ? ( 3'b0 ) : ( pkt_mod_i ); 

            // end of packet 
            pkt_fifo_status_o[6]    = 1'b1;

            // если принудительно закончили пакет ставим, будто была CRC-ошибка,
            // хотя, конечно, это не так...
            pkt_fifo_error_o[0]     = force_eop ? ( 1'b1 ) : ( frame_crc_err_i );
          end

      end
  end

assign pkt_fifo_val_o = ( fifo_rd_req_o && ( ( next_state == READ_S ) || ( next_state == IDLE_S ) ) ) || 
                        ( state == ERR_END_S );

logic [15:0] pkt_len;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    pkt_len <= 16'd0;
  else
    if( next_state == IDLE_S )
      // сразу инициализируемся размером CRC
      // чтобы не добавлять в конце пакета
      pkt_len <= 16'd4;
    else
      if( pkt_fifo_val_o )
        pkt_len <= pkt_len + 16'd8;

logic [3:0] last_word_bytes_cnt;

assign last_word_bytes_cnt = ( pkt_fifo_status_o[2:0] == 3'd0 ) ? ( 4'd8 ) : ( pkt_fifo_status_o[2:0] );

always_comb
  begin
    pkt_len_o = 16'd0;
    
    // выставляем размер только в момент eop
    // к накопленному счетчику добавляем то, что насчиталось в последнем слове
    if( pkt_fifo_val_o && pkt_fifo_status_o[6] )
      begin
        pkt_len_o = pkt_len + last_word_bytes_cnt; 
      end
  end

// watchdog нужен для корректной обработки следующей ситуации:
// по каким-то причинам получилось так, что к нам пришла часть пакета,
// а оставшаяся не дошла... то есть её не положили в фифошку.
// в таком случае мы будем висеть в READ_S и ждать окончания пакета
// если никогда не будет следующего пакета, то мы будем просто так висеть
// и ждать что может быть не очень правильно. поэтому мы отсчитываем
// максимальное количество тактов между словами, которые к нам могут приходить
// и если после предыдущего чтения прошло слишком много тактов, то форсируем
// окончание пакета

// худший случай, очевидно, при случае 10 Mbit/s.
// пропускная способность выходной системной шины составляет 62.5 Mhz * 64 bit = 4000 Mbit/s
// следовательно надо ожидать чтение раз в 4000/10 = 400 тактов. 
// для перестраховки увеличим это значение в 1.5 раза - до 600 тактов.

localparam MAX_TICK_WITHOUT_READ = 600;
localparam WDT_WIDTH             = $clog2( MAX_TICK_WITHOUT_READ + 1 );

logic [WDT_WIDTH-1:0] watchdog_cnt;

assign watchdog_failed = ( watchdog_cnt >= MAX_TICK_WITHOUT_READ );

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    watchdog_cnt <= '0;
  else
    if( ( state != READ_S ) || fifo_rd_req_o )
      watchdog_cnt <= '0;
    else
      if( ( state == READ_S ) && !watchdog_failed )
        watchdog_cnt <= watchdog_cnt + 1'd1;

// synthesis translate_off

always @( posedge watchdog_failed )
  begin
    $warning( "Watchdog failed!" );
  end

// synthesis translate_on

endmodule
