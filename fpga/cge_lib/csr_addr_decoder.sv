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
  Задача модуля распихать один csr_if в SLAVE_CNT по базовым
  оффсетам. ( Похоже на то, что делает amm_addr_decoder ).

*/

module csr_addr_decoder
#( 
  parameter SLAVE_CNT  = 5, 
  parameter ADDR_W     = 10,
  parameter BE_W       = 2,
  parameter DATA_W     = BE_W * 8

)
(
  input         [SLAVE_CNT:0][ADDR_W-1:0] base_addr_i,

  csr_if.slave                            master_csr_if,
  
  csr_if.master                           slave_csr_if[SLAVE_CNT-1:0]


);
//**************************************************************
// Декодирование адреса
//**************************************************************

logic [ADDR_W-1:0]      cur_master_addr;


assign cur_master_addr = master_csr_if.addr;

// Если адрес не попадает ни под один из заданных диапазонов,
// то slave_num_one_hot останется равным 0.
// Это сделано для того, чтобы адрес от мастера, который больше, 
// чем адреса, находящиеся в старшем валидном диапазоне, 
// не приводили к подаче невалидных транзакций.
logic [SLAVE_CNT-1:0] slave_num_one_hot;

// маска вида 111110000 - переход из 0 в 1 дает нам one_hot номер 
logic [SLAVE_CNT-1:0] slave_num_range_mask;

// находим переход в маске из 0 в 1 - она даст нам выбранный банк
always_comb
  begin
    slave_num_one_hot = '0;
    for( int i = 0; i < SLAVE_CNT; i++ )
      begin
        if( slave_num_range_mask[i] == 1'b1 )
          begin
            slave_num_one_hot[ i ] = 1'b1;
            break;
          end
      end          
  end

always_comb
  begin
    for( int i = 0; i < SLAVE_CNT; i++ )
      begin
        slave_num_range_mask[i] = ( cur_master_addr < base_addr_i[ i + 1 ] );
      end
  end


//**************************************************************
// Коммутация шин
//**************************************************************

// Для красоты времянок можно было бы занулить
// сигналы для неактивных слейвов, но это приведет
// к существенному увеличению ресурсов, поэтому оставляю так.

logic [SLAVE_CNT-1:0][DATA_W-1:0] slave_rdata_w;

genvar g;
generate
  for( g = 0; g < SLAVE_CNT; g++ )
    begin : g_slave
      assign slave_csr_if[g].addr    = master_csr_if.addr - base_addr_i[g];
      assign slave_csr_if[g].wr_data = master_csr_if.wr_data;
      assign slave_csr_if[g].be      = master_csr_if.be;
      assign slave_csr_if[g].wr_en   = master_csr_if.wr_en && slave_num_one_hot[g];
      assign slave_rdata_w[g]        = slave_csr_if[g].rd_data;
    end
endgenerate

one_hot_mux #(
  .INPUT_CNT                              ( SLAVE_CNT                             ), 
  .DATA_W                                 ( DATA_W                                )
) one_hot_mux_rdata (
  .sel_one_hot_i                          ( slave_num_one_hot                     ),

  .data_i                                 ( slave_rdata_w                         ),
  .data_o                                 ( master_csr_if.rd_data                 )
);


endmodule
