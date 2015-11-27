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
  Демультиплексор пакетных интерфейсов.

*/

import eth_pkt_lib::*;

module eth_pkt_demux
#( 
  parameter eth_pkt_if_t IF_PROPERTIES = eth_pkt_lib::DEFAULT_PROPERTIES,
  parameter TX_DIR        = 2,

  // использовать ли задержку на выходе демультиплексора
  parameter USE_DELAY         = 0
)
(
  input                         rst_i,
  input           [TX_DIR-1:0]  tx_dir_mask_i,
  eth_pkt_if.i                  pkt_i,  
  eth_pkt_if.o                  pkt_o[TX_DIR-1:0]

);


logic [TX_DIR-1:0]                  out_val;
logic                               in_ready;

logic [TX_DIR-1:0]                  out_ready;
logic [TX_DIR-1:0]                  out_ready_masked;

generate
  genvar g;
  for( g = 0; g < TX_DIR; g++ )
    begin :  g_o_pkts
      eth_pkt_if #( .IF_PROPERTIES ( IF_PROPERTIES ) ) _pkt( pkt_i.clk );

      assign _pkt.data       = pkt_i.data;
      assign _pkt.sop        = pkt_i.sop;
      assign _pkt.eop        = pkt_i.eop;
      assign _pkt.mod        = pkt_i.mod;
      assign _pkt.tuser      = pkt_i.tuser;

      //TODO: возможно более хитрая логика...
      //      т.к. если ready появляется только после val, то pkt_o.val никогда и не появится...
      assign _pkt.val        = pkt_i.val && tx_dir_mask_i[g] && in_ready;
      assign out_ready[g]    = _pkt.ready;
      

      eth_pkt_if_delay #( 
        .IF_PROPERTIES                          ( IF_PROPERTIES             ), 
        .DELAY                                  ( USE_DELAY ? ( 1 ) : ( 0 ) )
      ) pkt_d (
        .rst_i                                  ( rst_i                     ),
        .pkt_i                                  ( _pkt                      ),
        .pkt_o                                  ( pkt_o[g]                  )

      );
    end
endgenerate

assign pkt_i.ready = in_ready;

// маскируем те направления, куда направлять не хотим
always_comb
  begin
    for( int i = 0; i < TX_DIR; i++ )
      begin
        if( tx_dir_mask_i[i] == 1'b0 )
          out_ready_masked[i] = 1'b1;
        else
          out_ready_masked[i] = out_ready[i]; 
      end
  end

// сигнал показывает, что все приемники пакета готовы его принимать
// поэтому мы сами готовы к новому пакету.
assign in_ready = &out_ready_masked;


endmodule
