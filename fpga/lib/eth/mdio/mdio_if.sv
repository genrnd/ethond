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
   Интерфейс для управления mdio.
   Просто через этот интерфейс прокидываются csr.

*/

interface mdio_if( input clk_i );
  
  logic        rst;
  logic        run;
  logic [1:0]  cop;
  logic        fw_loading;

  logic [5:0]  divider;
  
  logic [4:0]  phy_addr;
  logic [4:0]  dev_addr;

  logic [15:0] wr_data;
  
  logic [15:0] fw_wr_data_w0;
  logic [15:0] fw_wr_data_w1;

  logic        fw_rst;
  logic        fw_run;
  
  logic [15:0] rd_data;
  logic        rd_data_val;
  logic        busy;

  logic        fw_busy;

modport slave(
  
  input       rst,
              run,
              cop,
              fw_loading,

              phy_addr,
              dev_addr,

              wr_data,
              divider,

              fw_wr_data_w0,
              fw_wr_data_w1,

              fw_rst,
              fw_run,
  
  output      rd_data,
              rd_data_val,
              busy,
              fw_busy
 
);

modport master(

  output      rst,
              run,
              cop,
              fw_loading,

              phy_addr,
              dev_addr,

              wr_data,
              divider,

              fw_wr_data_w0,
              fw_wr_data_w1,

              fw_rst,
              fw_run,
  
  input       rd_data,
              rd_data_val,
              busy,
              fw_busy

);


endinterface
