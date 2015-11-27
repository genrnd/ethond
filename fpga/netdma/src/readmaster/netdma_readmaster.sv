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
  The netdma_readmaster module is the one of three major modules of netdma.
  It is responsible for all aspects of readind data trough memory mapped 
  interface, address counting, byte counting, pushing data to the streaming
  interface towards physical network. 

  Submodule hierarchy:

  * readmaster:
  |-- * mm2st_adapter
      |-- * bytes_reorder_unit [optional]
      |-- * amm_data_aligner [optional]
      |-- * fifo_showahead   

  1.0 -- Initial release

  */


module netdma_readmaster #(

  parameter                             DATA_WIDTH                = 64,

  parameter                             FIFO_DEPTH                = 64,

  parameter                             FIFO_ALMOST_FULL_VALUE    = 32,

  parameter                             BYTES_REORDER_ENABLE      = 0,

  parameter                             UNALIGNED_ACCESS_ENABLE   = 1,
  
  parameter                             WORD_ADDRESSING           = 1
  )
  (
  
  input                                 clk_i,
  
  input                                 rst_i,

  input  netdma_pkg::master_control_t   master_control_i,
  
  output netdma_pkg::master_response_t  master_response_o,
  
  netdma_mm_read_interface.master       mm_read_if,
  
  netdma_src_interface.master           src_if 
);

  import netdma_pkg::*;

  
  // Because typycaly dataunit is greater than one byte, lower bits of bytecount
  // is not used in dataunit counting, it's used in formation of empty signal of
  // src_if. So it's useful to separate bytecount that counts whole dataunits and 
  // the bytecount rebinder. REM_WIDTH parameter is used as the delimiter of
  // this parts 

  localparam BYTE_NUM  = (DATA_WIDTH / 8);
  localparam REM_WIDTH = $clog2(BYTE_NUM); //REMinder

  descriptor_t descriptor;
  assign descriptor = master_control_i.descriptor;
      
  // A signal from mm2st_adapter output that indicates a new read request on memory
  // interface. The logic should increment address_reg value and decrement
  // bytecount1_reg value that counts pended read transactions 
  logic new_pending;

  // A signal from mm2st_adapter output that indicates a new dataunit got on memory
  // interface with readdatavalid signal. The logic should decrement
  // bytecount2_reg value than counts got and pushed to the tx_fifo_buf
  // datauntits
  logic new_dataunit;

  // Decode read_control_fsm state to get run signal 
  logic  [3:0] flow_control_decoded;
  decoder #(2) decoder1( master_control_i.flow_control, flow_control_decoded);
  logic  run;
  assign run  = flow_control_decoded[1];

  // Then get posedge signal of run that drives counters reload to the values of
  // the new descriptor
  logic run_posedge;
  posedge_detector run_posedge_detector ( clk_i, rst_i, run, run_posedge );

  logic [REM_WIDTH-1:0] reminder;
  assign reminder = descriptor.control_field.bytecount[REM_WIDTH-1:0];

  logic [1:0] PRE_INCR; //used as a const
  generate
    if( UNALIGNED_ACCESS_ENABLE )
      assign PRE_INCR = 2'd1; // If unaligned access enable, we should request
    else                      // more dataunit
      assign PRE_INCR = 2'd0;
  endgenerate

  // This wire is used to load bytecount registers at the start of the the new
  // descriptor processing. If reminder value isn't zero, we must do one more
  // reading
  logic [15-REM_WIDTH:0] bytecount;
  always_comb 
    if( reminder == 0 )      
      bytecount = descriptor.control_field.bytecount[15:REM_WIDTH] + (PRE_INCR);
    else
      bytecount = descriptor.control_field.bytecount[15:REM_WIDTH] + (PRE_INCR + 2'b1);


  // ### Counters ###

  // The value of this register output to the address wire of memory interface
  logic [31:0]                       address_reg;

  // This is the counter that is decremented at every read request pending on memory 
  // interface. It is used to timely termination of read requests when the value
  // reaches zero
  logic [15-REM_WIDTH:0]             bytecount_reg1;

  // This is the counter that is decremented at every new dataunit got.
  // It is used to drive eop and empty signals on the datastream interface 
  // and termination of the descriptor processig when the value reaches zero
  logic [15-REM_WIDTH:0]             bytecount_reg2;

  // ### counters logic ###

  // Unlike writemaster, readmaster decrements bytecount from initial value to
  // zero.   

  always_ff @( posedge clk_i, posedge rst_i )
    if( rst_i )  
      begin
        address_reg    <= '0;
        bytecount_reg1 <= '0;
      end       
    else 
      if( run_posedge ) 
        begin
          address_reg    <= descriptor.address;
          bytecount_reg1 <= bytecount;
        end
      else
        if( run & new_pending ) 
          begin
            address_reg    <= address_reg    + BYTE_NUM;
            bytecount_reg1 <= bytecount_reg1 - 1'b1;
          end

  always_ff @( posedge clk_i, posedge rst_i )
    if( rst_i )
       bytecount_reg2 <= '0;
    else
      if( run_posedge ) //ENA
        bytecount_reg2 <= bytecount;
        else 
          if( run & new_dataunit )
            bytecount_reg2 <= bytecount_reg2 - 1'b1;

  // ### forming signals to the netdma_mm2st_adapter submodule

  // The signal which causes active state of read requests pending on memory
  // interface. ~run_posedge signal is necessary, because at this moment 
  // address reg have not been updated 
  logic  st2mm_run_requests;
  assign st2mm_run_requests = ( bytecount_reg1 != 0 ) & ( run & ~run_posedge );

  // st2mm_run_receive is used only in the data aligner, so if the feature is
  // disabled, explisitly remove this logic 
  logic  st2mm_run_receive;
  generate
    if( UNALIGNED_ACCESS_ENABLE )
      assign st2mm_run_receive = ( bytecount_reg2 != 1) & ( run & ~run_posedge );
    else
      assign st2mm_run_receive = '0;
  endgenerate


  logic eop;
  // if unaligned access enable, a count of alligned words at the output of the
  // aligner (what bytecount2_reg does) is always one less than a count of
  // unaligned dataunits, that comes from interconnect. So in this case end 
  generate
    if( UNALIGNED_ACCESS_ENABLE )
      assign eop = ( bytecount_reg2 == 2 ) & ( run & new_dataunit );
    else
      assign eop = ( bytecount_reg2 == 1 ) & ( run & new_dataunit );
  endgenerate

  
  // According to specification of avalon streaming interface, a sink interface
  // should react to the empty signal only when the eop signal is active.
  // For the where this condition is not met, we tie the empty signal to the eop
  logic [REM_WIDTH-1:0] empty;
  assign empty = ({1'b1, {(REM_WIDTH){1'b0}}} - {1'b0, reminder}) & {(REM_WIDTH){eop}}; 


  // ### signals output to the read control module ###

  assign master_response_o.eop       = eop;
  assign master_response_o.error     = '0;
  assign master_response_o.bytecount = '0;

  // ### submodules ###

  netdma_mm2st_adapter #(
    .DATA_WIDTH                           ( DATA_WIDTH                         ),
    .FIFO_DEPTH                           ( FIFO_DEPTH                         ),
    .FIFO_ALMOST_FULL_VALUE               ( FIFO_ALMOST_FULL_VALUE             ),
    .BYTES_REORDER_ENABLE                 ( BYTES_REORDER_ENABLE               ),
    .UNALIGNED_ACCESS_ENABLE              ( UNALIGNED_ACCESS_ENABLE            ),
    .WORD_ADDRESSING                      ( WORD_ADDRESSING                    )
    ) mm2st (
    .mm_read_if                           ( mm_read_if                         ),
    .src_if                               ( src_if                             ), 
    .clk_i                                ( clk_i                              ),
    .rst_i                                ( rst_i                              ),
    /*datastream related wires*/
    .eop_i                                ( eop                                ),
    .empty_i                              ( empty                              ),
    .run_posedge_i                        ( run_posedge                        ),
    /*memory mapped interface related wires*/
    .address_i                            ( address_reg                        ),
    .run_requests_i                       ( st2mm_run_requests                 ),
    .run_receive_i                        ( st2mm_run_receive                  ),
    .new_pending_o                        ( new_pending                        ),
    .new_dataunit_o                       ( new_dataunit                       )
    );

endmodule
