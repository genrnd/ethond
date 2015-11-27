/*
  Legal Notice: Copyright 2015 STC Metrotek. 

  This file is part of the Netdma ip core.

  Netdma ip core is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Netdma ip core is distributed in the hope that it will be useful, but 
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Netdma ip core. If not, see <http://www.gnu.org/licenses/>.
*/
/*
  Author: Dmitry Hodyrev d.hodyrev@metrotek.spb.ru 
  Date: 22.10.2015
*/
/*
  This module contains a simpe state machine that drives readmaster/writemaster
  and signals make_report (causes creating a report about done transaction for
  host processor), fifo_rdreq (retrives used descriptor from fifo buffer).
  
  1.0 -- Initial release

*/

module netdma_control_fsm
 (
  input                                         clk_i,
 
  input                                         rst_i,
 
  input                                         fifo_empty_i,
 
  input                                         go_i,
  
  input                                         eop_i,

  input                                         error_i,

  output                                        make_report_o,

  output                                        fifo_rdreq_o,
 
  output [1:0]                                  state_o
  );

  typedef enum logic [1:0] { 
    IDLE_S,  
    RUN_S,  
    DONE_S
  } flow_control_t;
  
  flow_control_t state, state_next;

  always_ff @(posedge clk_i, posedge rst_i)
    if( rst_i )
      state <= IDLE_S;
    else       
      state <= state_next;

  logic make_report;
  logic fifo_rdreq;

  // a new descriptor is seen 
  logic  descriptor_on_queue;
  assign descriptor_on_queue = ~fifo_empty_i & go_i;

  always_comb 
    begin : FSM
      state_next        = state;
      make_report       = '0;
      fifo_rdreq        = '0;
      unique case( state )
        IDLE_S : 
          begin
            if( descriptor_on_queue ) 
              state_next = RUN_S;
          end
        RUN_S  : 
          begin 
            if( error_i | eop_i )
              begin  
                state_next   = DONE_S;
                make_report  = '1;
                fifo_rdreq   = '1;
              end
          end
        DONE_S :
          begin 
            if( descriptor_on_queue ) 
              state_next = RUN_S;
            else  // no more descriptors
              state_next = IDLE_S;
          end
      endcase
    end : FSM
 
  assign state_o       = state;
  assign make_report_o = make_report;
  assign fifo_rdreq_o  = fifo_rdreq;

endmodule

