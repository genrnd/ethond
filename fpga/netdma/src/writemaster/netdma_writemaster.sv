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
  The netdma_writemaster module is the one of three major modules of the netdma.
  It is responsible for all aspects of getting data from the streaming sink
  interface, address counting, byte counting, writing data through the memory
  mapping write interface. 

  Submodule hierarchy:

  * writemaster:
  |-- * st2mm_adapter
      |-- * bytes_reorder_unit [optional]

  1.0 -- Initial release

*/


module netdma_writemaster #(
    
  parameter                                    DATA_WIDTH                = 64,

  parameter                                    BYTES_REORDER_ENABLE      = 0,
  
  parameter                                    WORD_ADDRESSING           = 1
 )
 (
  input                                        clk_i,
 
  input                                        rst_i,

  input  netdma_pkg::master_control_t          master_control_i,
  
  output netdma_pkg::master_response_t         master_response_o,
 
  netdma_mm_write_interface.master             mm_write_if,
 
  netdma_snk_interface.master                  snk_if
);

  import netdma_pkg::*;

  // Because typycaly dataunit is greater than one byte, lower bits of bytecount
  // is not used in dataunit counting, it's used in formation of empty signal of
  // src_if. So it's useful to separate bytecount that counts whole dataunits and 
  // the bytecount rebinder. REM_WIDTH parameter is used as the delimiter of
  // this parts 

  localparam BYTES_NUM  = ( DATA_WIDTH / 8 );
  localparam REM_WIDTH = $clog2( BYTES_NUM ); //REMinder

  descriptor_t descriptor;
  assign descriptor = master_control_i.descriptor;
    

  // decode write control state and get needful signals
  logic  [3:0] flow_control_decoded;
  decoder #(2) decoder1( master_control_i.flow_control, flow_control_decoded);
  logic  run, done;
  assign run   = flow_control_decoded[1];
  assign done  = flow_control_decoded[2];

  // Then get posedge signal of run that drives counters reload to the values of
  // the new descriptor
  logic run_posedge;
  posedge_detector run_posedge_detector ( clk_i, rst_i, run, run_posedge );

  // A signal from the st2mm_adapter output. It is active only when a new dataunit 
  // is transmitted to the memory through memory interface.
  // If this signal active, the values of address_reg and bytecount_reg is
  // incremented
  logic new_transaction;
 
  // conjunction of all signals than cat initiate descriptor processing
  // termination
  logic  endoftransaction;
 
  // st2mm_adapter output. A copy of the startofpacket input signal of the streaming
  //  interface
  logic sop;

  // Signals that active when the state machine is in corresponding state.
  // just to make code more compact
  logic wait_for_sop;
  logic run_state;

  // ### a little FSM ###

  typedef enum logic [1:0] {
    IDLE_S,     // wait for descriptor
    WAIT_SOP_S, // wait for a packet
    RUN_S       // wait eod of packet or bytecount limit
  } writemaster_fsm_t;

  writemaster_fsm_t state, state_next;

  always_ff @(posedge clk_i, posedge rst_i)
    if( rst_i )
      state <= IDLE_S;
    else
      if( endoftransaction )
        state <= IDLE_S;
      else
        state <= state_next;

  always_comb
    begin : FSM
      state_next   = state;
      wait_for_sop = '0;
      run_state    = '0;
      unique case( state )
        IDLE_S     :
          begin
            if( run_posedge ) 
              state_next = WAIT_SOP_S;
          end
        WAIT_SOP_S :
          begin
            wait_for_sop = 1'b1;
            if( sop ) 
              state_next = RUN_S;
          end
        RUN_S : 
          begin
            run_state = 1'b1;
            if( endoftransaction ) 
              state_next = IDLE_S;
          end
      endcase
    end : FSM
  
  // ### counters ###
  
  logic [31:0]             address_reg;
  logic [15-REM_WIDTH:0]   bytecount_reg;

  // Unlike readmaster, writemaster increments bytecount from zero

  always_ff @(posedge clk_i, posedge rst_i)
    if( rst_i )                               
      address_reg   <= '0;
    else 
      if( new_transaction | run_posedge )  //ENA
        if( run_posedge )                       
          address_reg   <= descriptor.address;
        else                                   
          address_reg   <= address_reg + BYTES_NUM;


  always_ff @(posedge clk_i, posedge rst_i)
    if( rst_i )         
      bytecount_reg <= '0;
    else 
      if( new_transaction | run_posedge )
        if( run_posedge ) 
          bytecount_reg <= '0; 
        else             
          bytecount_reg <= bytecount_reg + 1'b1;
 

  // the endofpacket signal becomes active only when a dataunit with the
  // enofpacket indicator is transmited on the memory interface
  logic  eop, st2mm_eop;
  assign eop = st2mm_eop & new_transaction; 

  // The signal active only if the error sensetivity set in the descriptor flags
  logic  error, st2mm_error;
  assign error = st2mm_error & descriptor.control_field.stop_on_error; 

  logic  bytecount_limit;
  assign bytecount_limit = ( bytecount_reg == descriptor.control_field.bytecount[15:REM_WIDTH]); 

  assign endoftransaction = done | error | eop | bytecount_limit;

  // The signal that causes activity on memory mapped and streaming interfaces
  // in the st2mm_adapter submodule
  logic  st2mm_run;
  assign st2mm_run = ( run_state | wait_for_sop ) & ~bytecount_limit;

  logic [REM_WIDTH-1:0] empty;

  // if the transaction terminated not by a bytecount limit, we should add 1 to
  // the bytecount_reg, because when module gets endofpacket signal, it creates
  // report immediately and have no time to take into account corresponding data unit
  logic [15-REM_WIDTH:0] real_bytecount;
  assign real_bytecount = ( bytecount_limit ) ? bytecount_reg : bytecount_reg + 1'b1;

  // ### signals output to the write control module ###

  assign master_response_o.bytecount  = {real_bytecount, {(REM_WIDTH){1'b0}}} - empty;
  assign master_response_o.error      = error;
  assign master_response_o.eop        = eop | bytecount_limit;

  netdma_st2mm_adapter #(
    .DATA_WIDTH                     ( DATA_WIDTH                               ), 
    .BYTES_REORDER_ENABLE           ( BYTES_REORDER_ENABLE                     ),
    .WORD_ADDRESSING                ( WORD_ADDRESSING                          )
    ) st2mm (
    .snk_if                         ( snk_if                                   ),
    .mm_write_if                    ( mm_write_if                              ),
    .clk_i                          ( clk_i                                    ),
    .rst_i                          ( rst_i                                    ),
    .run_i                          ( st2mm_run                                ),
    .address_i                      ( address_reg                              ),
    .wait_for_sop_i                 ( wait_for_sop                             ),
    .new_transaction_o              ( new_transaction                          ),
    .sop_o                          ( sop                                      ),
    .eop_o                          ( st2mm_eop                                ),
    .empty_o                        ( empty                                    ),
    .error_o                        ( st2mm_error                              ) 
  );

endmodule  

