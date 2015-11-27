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

interface m88e1512_if;

logic             clk125m;

logic             rx_clk;
logic  [3:0]      rx_data;
logic             rx_ctrl;

logic             tx_clk;
logic  [3:0]      tx_data;
logic             tx_ctrl;

logic             mdc;
wire              mdio;

logic             nreset;

logic             ptpclk;
logic             ptp_int;
wire              ptp_io;

modport trg(
  input              clk125m,

  input              rx_clk,
  input              rx_data, 
  input              rx_ctrl,

  output             tx_clk,
  output             tx_data,
  output             tx_ctrl,

  output             mdc,
  inout              mdio,

  output             nreset,

  output             ptpclk,
  input              ptp_int,
  inout              ptp_io
);

modport adapter(
  output             clk125m,

  output             rx_clk,
  output             rx_data, 
  output             rx_ctrl,

  input              tx_clk,
  input              tx_data,
  input              tx_ctrl,

  input              mdc,
  inout              mdio,

  input              nreset,

  input              ptpclk,
  output             ptp_int,
  inout              ptp_io
);


endinterface
