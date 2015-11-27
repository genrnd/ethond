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

interface csr_if(
  
  input clk  

);
   parameter A_WIDTH  = 10;
   parameter D_WIDTH  = 16;
   parameter BE_WIDTH =  2;
   
   logic [A_WIDTH-1:0]  addr;
   logic [BE_WIDTH-1:0] be;

   logic [D_WIDTH-1:0]  wr_data;
   logic                wr_en;

   logic [D_WIDTH-1:0]  rd_data;


modport master(

   output  wr_data,
           wr_en,
           addr,
           be,

   input   rd_data,
           clk

);

modport slave(
   input  wr_data,
          wr_en,
          addr,
          be,
          clk,

   output rd_data

);

endinterface
