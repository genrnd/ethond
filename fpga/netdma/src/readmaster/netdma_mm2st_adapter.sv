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
  This module deals with memory mapped read interface and streamning source
  interface signals. It is responsible for correct interface signal assignments,
  aligning dataunits if needed and intermediate buffering (beacuse read interface
  assumed pipelined). It also includes feature of byte reordering and
  startofpacket generation logic.

  Submodule hierarchy:
  
  * mm2st_adapter
  |-- * bytes_reorder_unit [optional]
  |-- * amm_data_aligner [optional]
  |-- * fifo_showahead   

  1.0 -- Initial release

*/

module netdma_mm2st_adapter #(

  parameter                               DATA_WIDTH                = 64,

  parameter                               FIFO_DEPTH                = 64,

  parameter                               FIFO_ALMOST_FULL_VALUE    = 32,

  parameter                               BYTES_REORDER_ENABLE      = 0,

  parameter                               UNALIGNED_ACCESS_ENABLE   = 1,
  
  parameter                               WORD_ADDRESSING           = 1
  )
 (
  netdma_mm_read_interface.master         mm_read_if,
  
  netdma_src_interface.master             src_if,
  
  input                                   clk_i,
 
  input                                   rst_i,

  input                                   eop_i,
 
  input [($clog2(DATA_WIDTH / 8))-1:0]    empty_i,
 
  input                                   run_posedge_i,

  input [31:0]                            address_i,
  
  input                                   run_requests_i,

  input                                   run_receive_i,
 
  output                                  new_pending_o,

  output                                  new_dataunit_o
); 

  localparam NUM_BYTES        = (DATA_WIDTH / 8);
  localparam EMPTY_WIDTH      = $clog2(NUM_BYTES);
  localparam ADDRESS_REMINDER = EMPTY_WIDTH;

  localparam FIFO_WIDTH       = DATA_WIDTH    // data
                              + 1             // valid
                              + EMPTY_WIDTH   // empty
                              + 2;            // sop, eop


  // internal wires
  logic empty, almost_full, rdreq, wrreq, sop;

  logic [DATA_WIDTH-1:0] readdata; 
  logic                  readdatavalid;

  // typedef of the structure passed through fifo
  typedef struct packed {
    logic                         sop;
    logic                         eop;
    logic [EMPTY_WIDTH-1:0]       empty;
    logic                         valid;
    logic [DATA_WIDTH-1:0]        data;
  } rm_fifo_data_unit_t;

  rm_fifo_data_unit_t st_side_data, mm_side_data;

 
 // ### sop logic ###

  logic sop_trigger, sop_next;
  always_ff @(posedge clk_i, posedge rst_i)
    if( rst_i ) 
      sop_trigger = '0;
    else       
      sop_trigger = sop_next;
    
  always_comb 
    begin : sop_nextstate
      sop_next = sop_trigger;
      if( run_posedge_i == '1 ) 
        sop_next = '1;
      if( ( sop_trigger == '1 ) & mm_side_data.valid )
        begin
          sop      = '1;
          sop_next = '0;    
        end
      else
        sop = '0;
  end : sop_nextstate 
  // ******************************************************** //
  
  // memory-mapped side assignments     
  logic read;
  assign read = run_requests_i & ~almost_full;
  // memory-mapped side assignments    
  assign mm_side_data.data             = readdata;
  assign mm_side_data.valid            = readdatavalid; 
  assign mm_side_data.sop              = sop;
  assign mm_side_data.eop              = eop_i;
  assign mm_side_data.empty            = empty_i;

  generate
    if( WORD_ADDRESSING)
      assign mm_read_if.address        = address_i[31:ADDRESS_REMINDER];
    else
      assign mm_read_if.address        = address_i;
  endgenerate

  assign mm_read_if.read               = read;

  // streaming side assignments                                    
  assign src_if.valid           = st_side_data.valid & ~empty;
  assign src_if.startofpacket   = st_side_data.sop; 
  assign src_if.endofpacket     = st_side_data.eop;
  assign src_if.empty           = st_side_data.empty; 

  // generate byte reordering, if this feature enable
  generate 
    if( BYTES_REORDER_ENABLE )
      begin : bytes_reorder
        bytes_reorder #(
          .NUM_BYTES                    ( NUM_BYTES                           ))   
        the_bytes_reorder(
          .data_unit                    ( st_side_data.data                   ), 
          .reordered_data_unit          ( src_if.data                         )
        );
      end : bytes_reorder
    else
      assign src_if.data = st_side_data.data;
  endgenerate

  generate 
    if( UNALIGNED_ACCESS_ENABLE )
      begin : unaligned_access
        amm_data_aligner #(
          .DATA_WIDTH                   ( DATA_WIDTH                          )) 
        aligner(
          .clk_i                        ( clk_i                               ),
          .rst_i                        ( rst_i                               ),
          .run_i                        ( run_receive_i                       ),
          .offset_i                     ( address_i[ADDRESS_REMINDER-1:0]     ),
          .readdata_i                   ( mm_read_if.readdata                 ),
          .readdatavalid_i              ( mm_read_if.readdatavalid            ),
          .readdata_o                   ( readdata                            ),
          .readdatavalid_o              ( readdatavalid                       )
        );
      end : unaligned_access
    else
      begin : aligned_access // (bypass)
        assign readdata      = mm_read_if.readdata;      
        assign readdatavalid = mm_read_if.readdatavalid;
      end : aligned_access
  endgenerate 

  // internal assignments

  assign wrreq                         = mm_side_data.valid;
  assign rdreq                         = src_if.ready & ~empty;
  assign new_pending_o                 = read & ~mm_read_if.waitrequest;
  assign new_dataunit_o                = mm_side_data.valid;

  fifo_showahead #(
    .WIDTH                              ( FIFO_WIDTH                          ),
    .DEPTH                              ( FIFO_DEPTH                          ))
  rm_fifo_inst(
    .aclr                               ( rst_i                               ),
    .clock                              ( clk_i                               ),
    .data                               ( mm_side_data[FIFO_WIDTH-1:0]        ),
    .rdreq                              ( rdreq                               ),
    .wrreq                              ( wrreq                               ),
    .almost_full                        ( almost_full                         ),
    .empty                              ( empty                               ),
    .full                               (                                     ),
    .q                                  ( st_side_data[FIFO_WIDTH-1:0]        )
  );
 
  defparam rm_fifo_inst.scfifo_component.lpm_widthu        = $clog2(FIFO_DEPTH);
  defparam rm_fifo_inst.scfifo_component.almost_full_value = FIFO_ALMOST_FULL_VALUE;

endmodule
