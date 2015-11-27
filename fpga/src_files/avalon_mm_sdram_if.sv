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

interface avalon_mm_sdram_if
#(
  parameter ADDR_WIDTH        = 32,
  parameter DATA_WIDTH        = 64,
  parameter BURST_COUNT_WIDTH = 8,
  parameter BYTE_ENABLE_WIDTH = DATA_WIDTH/8
)
( );

logic                          clk;
logic [ADDR_WIDTH-1:0]         address;
logic [BURST_COUNT_WIDTH-1:0]  burst_count;
logic [DATA_WIDTH-1:0]         write_data;
logic [DATA_WIDTH-1:0]         read_data;

logic [BYTE_ENABLE_WIDTH-1:0]  byte_enable;

logic                          readdata_val;
logic                          write;
logic                          read;
logic                          wait_request;

modport master(
  output  clk,
          address,
          burst_count,
          write_data,
          byte_enable,
          write,
          read,

  input   wait_request,
          read_data,
          readdata_val

);


modport slave(
  input   clk,
          address,
          burst_count,
          write_data,
          byte_enable,
          write,
          read,

  output  wait_request,
          read_data,
          readdata_val

);

endinterface
