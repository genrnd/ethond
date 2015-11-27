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
  Сигналы от rx_pkt_fetcher и от conv_1G_top вынесли в отдельный
  интерфейс, что бы проще было тянуть и использовать.

*/

interface rx_engine_if( );

    logic [63:0]                  data;
    logic [7:0]                   status;
    logic [2:0]                   error;
    logic                         en;
    logic [15:0]                  pkt_len;

    logic                         wr_full;


// интерфейс rx_engine
modport engine(

   input           data,
                   status,
                   error,
                   en,
                   pkt_len,

   output          wr_full


);

// интерфейс, который ближе к физике
// назвали по rx_pkt_fetcher, который и является "родителем"
// этого интерфейса
modport fetcher(
   output          data,
                   status,
                   error,
                   en,
                   pkt_len,

   input           wr_full


);

endinterface
