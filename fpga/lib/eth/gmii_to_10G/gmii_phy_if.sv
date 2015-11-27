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
  Физический интерфейс gmii/mii. 
  Просто объединили сигналы в один интерфейс, что бы меньше тащить.

*/

interface gmii_phy_if();

  logic                             clk125m;

  logic                             gtx_clk;   // used only in GMII mode
  logic                             tx_clk;    // used only in MII mode
  logic                             tx_err;
  logic                             tx_en;
  logic [7:0]                       tx_d;

  logic                             rx_clk;
  logic                             rx_err;
  logic                             rx_dv;
  logic  [7:0]                      rx_d;
  logic                             crs;
  
  // младшие три бита - скорость на порту 1G
  // старший бит в нуле - выбрана скрость 10G

  logic  [3:0]                      rx_speed;
  logic  [3:0]                      tx_speed;


modport phy(
   input    clk125m,

   output   gtx_clk,   
   input    tx_clk,    
   output   tx_err,
   output   tx_en,
   output   tx_d,

   input    rx_clk,
   input    rx_err,
   input    rx_dv,
   input    rx_d,
   input    crs,

   input    rx_speed,
            tx_speed

);

// направления как бы со стороны трансивера
modport trx(
   output    clk125m,
   input     gtx_clk,   
   output    tx_clk,    
   input     tx_err,
   input     tx_en,
   input     tx_d,

   output    rx_clk,
   output    rx_err,
   output    rx_dv,
   output    rx_d,
   output    crs,

   output    rx_speed,
             tx_speed
);

endinterface
