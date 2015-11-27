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

module one_hot_mux #(
  parameter INPUT_CNT = 2, 
  parameter DATA_W    = 32
) (
  input  [INPUT_CNT-1:0]             sel_one_hot_i,

  input  [INPUT_CNT-1:0][DATA_W-1:0] data_i,

  output logic [DATA_W-1:0]                data_o
);


logic [DATA_W-1:0][INPUT_CNT-1:0] data_trans_w;


always_comb
  for( int i = 0; i < INPUT_CNT; i++ )
    for( int j = 0; j < DATA_W; j++ )
      data_trans_w[j][i] = data_i[i][j];

always_comb
  for( int i = 0; i < DATA_W; i++ )
    data_o[i] = |( sel_one_hot_i & data_trans_w[i] );


endmodule



