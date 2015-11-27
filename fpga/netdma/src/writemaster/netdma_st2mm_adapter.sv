/*
  Legal Notice: Copyright 2015 STC Metrotek. 

  This file is part of the Netdma ip core.

  Netdma ip core is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Netdma ip core is distributed in the hope that it will be useful, but 
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Netdma ip core. If not, see <http://www.gnu.org/licenses/>.
*/
/*
  Author: Dmitry Hodyrev d.hodyrev@metrotek.spb.ru 
  Date: 22.10.2015
*/
/*
  This module deals with memory mapped write interface and streamning sink
  interface signals. It is responsible for correct interface signal assignments,
  It also includes optional feature of byte reordering.

  Submodule hierarchy:
  
  * st2mm_adapter
  |-- * bytes_reorder_unit [optional]
 
  1.0 -- Initial release
*/


module netdma_st2mm_adapter #(
  
  parameter                                   DATA_WIDTH                = 64,

  parameter                                   BYTES_REORDER_ENABLE      = 0,

  parameter                                   WORD_ADDRESSING           = 1
  )
 (
  netdma_snk_interface.master                 snk_if,
  
  netdma_mm_write_interface.master            mm_write_if,
 
  input                                       clk_i,
 
  input                                       rst_i,
  
  input                                       run_i,
  
  input [31:0]                                address_i,
  
  input                                       wait_for_sop_i,

  output                                      new_transaction_o,
  
  output                                      sop_o,

  output                                      eop_o,
  
  output [$clog2( DATA_WIDTH / 8 ) - 1 : 0 ]  empty_o,
  
  output                                      error_o
  );

  localparam NUM_BYTES  = ( DATA_WIDTH / 8 );

  localparam ADDRESS_REMINDER = $clog2(NUM_BYTES);

  logic sop;
  assign sop = snk_if.startofpacket & snk_if.valid;

  // put valid data to the memory mapped interface
  logic write;
  assign write = ( wait_for_sop_i ) ? sop : run_i & snk_if.valid;
       
 // ### memory mapped interface ##
  
  generate
    if( WORD_ADDRESSING )
      assign mm_write_if.address        = address_i[31:ADDRESS_REMINDER];
    else
      assign mm_write_if.address        = address_i;
  endgenerate
  
  assign mm_write_if.write   = write; 
  // generate byte reordering, if this feature enable
  generate 
    if( BYTES_REORDER_ENABLE )
      begin : bytes_reorder
        bytes_reorder #(
          .NUM_BYTES                          ( NUM_BYTES                      ))   
        the_bytes_reorder(
          .data_unit                          ( snk_if.data                    ), 
          .reordered_data_unit                ( mm_write_if.data               )
        );
      end : bytes_reorder
    else
      assign mm_write_if.writedata = snk_if.data;
  endgenerate

 // ### streaming interface ###

  assign snk_if.ready = run_i & ~mm_write_if.waitrequest;

// ### output signals ###

  assign new_transaction_o  = write & ~mm_write_if.waitrequest;

  assign sop_o              = sop;
  assign eop_o              = snk_if.endofpacket;
  assign error_o            = snk_if.error;
  assign empty_o            = snk_if.empty;

endmodule
