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
  Интерфейс сигналов до ROM с идентификацией прошивки FPGA.

*/

interface fpga_id_if
#( 
  parameter D_WIDTH = 32,
  parameter A_WIDTH = 8
)
(
  input clk_i  
);

logic [A_WIDTH-1:0] rd_addr;
logic [D_WIDTH-1:0] rd_data;

modport slave(
  input  rd_addr,
  output rd_data

);

modport master(
  output  rd_addr,
  input   rd_data


);


endinterface

