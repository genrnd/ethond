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

module netdma_wrapper(
  input                         clk_i,

  netdma_cpu_interface          netdma_cpu_if0,
  netdma_cpu_interface          netdma_cpu_if1,
  netdma_mm_write_interface     netdma_write_if0,
  netdma_mm_write_interface     netdma_write_if1,
  netdma_mm_read_interface      netdma_read_if0,
  netdma_mm_read_interface      netdma_read_if1,
  
  eth_pkt_if.i  pkt_to_cpu_i   [1:0],
  eth_pkt_if.o  pkt_from_cpu_o [1:0]

);


netdma_src_interface          netdma_src_if [1:0]  ( );  
netdma_snk_interface          netdma_snk_if [1:0]  ( );



netdma #(
     // When "0", tx part (readmaster and it's control) will not be synthesized. 
     // Otherwise will.
    .TX_ENABLE                             ( 1                                ),
     // When "0", rx part (writemaster and it's control) will not be synthesized. 
     // Otherwise will.
    .RX_ENABLE                             ( 1                                ),
     // The width of a data unit used in one memory access act. Must be the same
     // width as readdata/writedata wires in mastered amm interfaces 
    .DATA_WIDTH                            ( 64                               ),
     // The depth of the fifo that holds descriptors on queue. Your network
     // driver must deal with this value to not overflow netdma with descriptors
    .DESC_FIFO_DEPTH                       ( 64                               ),
     // The depth of the fifo that holds reports of done rx descriptors ( the
     // most important is packet lengh ). It's strongly recommended not to do
     // this parameter smaller than DESC_FIFO_DEPTH
    .RX_RESPONSE_FIFO_DEPTH                ( 64                               ),
     // If you want irq request signal that rises up after it's event and then
     // keeps on until be cleared by driver, set this parameter in "1". Else you
     // will have irq event signal as a strobe after it's event
    .LATCH_IRQ_STATUS_ENABLE               ( 0                                ),
     // The depth of fifo that used in memory mapped to streaming adapter. The
     // effect of this parameter on troughput currently unknown, but it must be
     // at least greater than maximum count of pending read transactions on the
     // read master mastered interface
    .TX_FIFO_DEPTH                         ( 64                               ),
     // The maximum count of pending read transactions on the read master mastered 
     // interface
    .TX_MM_IF_MAX_PENDING_COUNT            ( 1                                ),
     // This parameter being set in "1" enables byte reordering from MSB to LSB
     // or vice versa in tx, like [[3][2][1][0]] --> [[0][1][2][3]]
    .TX_BYTES_REORDER_ENABLE               ( 0                                ),
     // When your kernel alocates for outgoing packet buffers addresses that aren't 
     // multiplies of the data unit size, you should set this parameter in "1"
    .TX_UNALIGNED_ACCESS_ENABLE            ( 1                                ),
     // Same as RX_BYTES_REORDER_ENABLE 
    .RX_BYTES_REORDER_ENABLE               ( 0                                ),
    // If this parameter set in "1", address wire width in memory mapped master 
    // interfaces (mm_read_if, mm_write_if) will be divided by count of bytes in
    // the dataunit size. In other ords, address wire will be trimmed in the 
    // least significant bits, so it will represent word address. If it set in
    // "0", there will be byte addressing
    .WORD_ADDRESSING                       ( 1                                )

    ) netdma0 (
    .clk_i                                 ( clk_i                            ),
    .rst_i                                 (                                  ),
    .cpu_if                                ( netdma_cpu_if0                   ),
    .mm_read_if                            ( netdma_read_if0                  ),
    .mm_write_if                           ( netdma_write_if0                 ),
    .src_if                                ( netdma_src_if[0]                 ),
    .snk_if                                ( netdma_snk_if[0]                 )
  );


netdma #(
     // When "0", tx part (readmaster and it's control) will not be synthesized. 
     // Otherwise will.
    .TX_ENABLE                             ( 1                                ),
     // When "0", rx part (writemaster and it's control) will not be synthesized. 
     // Otherwise will.
    .RX_ENABLE                             ( 1                                ),
     // The width of a data unit used in one memory access act. Must be the same
     // width as readdata/writedata wires in mastered amm interfaces 
    .DATA_WIDTH                            ( 64                               ),
     // The depth of the fifo that holds descriptors on queue. Your network
     // driver must deal with this value to not overflow netdma with descriptors
    .DESC_FIFO_DEPTH                       ( 64                               ),
     // The depth of the fifo that holds reports of done rx descriptors ( the
     // most important is packet lengh ). It's strongly recommended not to do
     // this parameter smaller than DESC_FIFO_DEPTH
    .RX_RESPONSE_FIFO_DEPTH                ( 64                               ),
     // If you want irq request signal that rises up after it's event and then
     // keeps on until be cleared by driver, set this parameter in "1". Else you
     // will have irq event signal as a strobe after it's event
    .LATCH_IRQ_STATUS_ENABLE               ( 0                                ),
     // The depth of fifo that used in memory mapped to streaming adapter. The
     // effect of this parameter on troughput currently unknown, but it must be
     // at least greater than maximum count of pending read transactions on the
     // read master mastered interface
    .TX_FIFO_DEPTH                         ( 64                               ),
     // The maximum count of pending read transactions on the read master mastered 
     // interface
    .TX_MM_IF_MAX_PENDING_COUNT            ( 1                                ),
     // This parameter being set in "1" enables byte reordering from MSB to LSB
     // or vice versa in tx, like [[3][2][1][0]] --> [[0][1][2][3]]
    .TX_BYTES_REORDER_ENABLE               ( 0                                ),
     // When your kernel alocates for outgoing packet buffers addresses that aren't 
     // multiplies of the data unit size, you should set this parameter in "1"
    .TX_UNALIGNED_ACCESS_ENABLE            ( 1                                ),
     // Same as RX_BYTES_REORDER_ENABLE 
    .RX_BYTES_REORDER_ENABLE               ( 0                                ),
    // If this parameter set in "1", address wire width in memory mapped master 
    // interfaces (mm_read_if, mm_write_if) will be divided by count of bytes in
    // the dataunit size. In other ords, address wire will be trimmed in the 
    // least significant bits, so it will represent word address. If it set in
    // "0", there will be byte addressing
    .WORD_ADDRESSING                       ( 1                                )

    ) netdma1 (
    .clk_i                                 ( clk_i                            ),
    .rst_i                                 (                                  ),
    .cpu_if                                ( netdma_cpu_if1                   ),
    .mm_read_if                            ( netdma_read_if1                  ),
    .mm_write_if                           ( netdma_write_if1                 ),
    .src_if                                ( netdma_src_if[1]                 ),
    .snk_if                                ( netdma_snk_if[1]                 )
  );




genvar i;
generate
  for( i = 0; i < 2; i++ )
    begin : netdma_pkt_if

      assign pkt_from_cpu_o[i].data   =  netdma_src_if[i].data;
      assign pkt_from_cpu_o[i].sop    =  netdma_src_if[i].startofpacket;
      assign pkt_from_cpu_o[i].eop    =  netdma_src_if[i].endofpacket;
      assign pkt_from_cpu_o[i].mod    =  ( netdma_src_if[i].empty == 'd0 ) ? ( 'd0 ) : ( 'd8 - netdma_src_if[i].empty );
      assign pkt_from_cpu_o[i].val    =  netdma_src_if[i].valid;
      assign pkt_from_cpu_o[i].tuser  =  '0;
      assign netdma_src_if[i].ready   =  pkt_from_cpu_o[i].ready;

      
      assign netdma_snk_if[i].data          = pkt_to_cpu_i[i].data;
      assign netdma_snk_if[i].startofpacket = pkt_to_cpu_i[i].sop;  
      assign netdma_snk_if[i].endofpacket   = pkt_to_cpu_i[i].eop;  
      assign netdma_snk_if[i].empty         = ( pkt_to_cpu_i[i].mod == 'd0 ) ? ( 'd0 ) : ( 'd8 - pkt_to_cpu_i[i].mod ); 
      assign netdma_snk_if[i].valid         = pkt_to_cpu_i[i].val;  
      assign pkt_to_cpu_i[i].ready          = netdma_snk_if[i].ready;
    end
endgenerate 




endmodule
