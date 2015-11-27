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
  This module contains an instance of netdma_control_fsm -- simpe state machine
  that takes some input from readmaster/writemaster and a descriptor buffer and
  drives make_report (informing host processor about done transaction) and
  fifo_rdreq (retrives used descriptor from descriptor buffer). Read control and
  write control both synthesizable from this source. Parameter MODE modificates
  report_o assignments to get tx or rx report type output. 
    
  1.0 -- Initial release

*/

module netdma_control #(

  parameter                             MODE = 0
 )
 (
  input                                 clk_i,
  
  input                                 rst_i,
  
  output [1:0]                          control_state_o,
  
  output [31:0]                         report_o,
  
  input  netdma_pkg::descriptor_t       descriptor_i,
  
  input                                 fifo_empty_i,
  
  output                                fifo_rdreq_o,
  
  input netdma_pkg::master_response_t   master_response_i,

  output netdma_pkg::master_control_t   master_control_o

);

  localparam READ_CONTROL  = 0;
  localparam WRITE_CONTROL = 1;

  import netdma_pkg::*;

  logic make_report; 

  generate 
    if (MODE == READ_CONTROL)
    begin : tx_assignments
        tx_report_t  tx_report;
        assign tx_report.is_report       = make_report;
        assign tx_report.disable_irq     = descriptor_i.control_field.disable_tx_irq;
        assign tx_report.error           = master_response_i.error;
        assign tx_report.sequence_number = descriptor_i.control_field.sequence_number;
        assign report_o                  = tx_report;
      end : tx_assignments
    else
      begin : rx_assignments
        rx_report_t rx_report;
        assign rx_report.is_report       = make_report;
        assign rx_report.disable_irq     = descriptor_i.control_field.disable_rx_irq;
        assign rx_report.error           = master_response_i.error;
        assign rx_report.sequence_number = descriptor_i.control_field.sequence_number;
        assign rx_report.bytecount       = master_response_i.bytecount;
        assign report_o                  = rx_report;
      end : rx_assignments
  endgenerate
 
  logic [1:0] flow_control;

  netdma_control_fsm fsm(
    .clk_i                      ( clk_i                                ),
    .rst_i                      ( rst_i                                ),
    .fifo_empty_i               ( fifo_empty_i                         ),
    .go_i                       ( descriptor_i.control_field.go        ),
    .eop_i                      ( master_response_i.eop                ),
    .error_i                    ( master_response_i.error              ),
    .make_report_o              ( make_report                          ),
    .fifo_rdreq_o               ( fifo_rdreq_o                         ),
    .state_o                    ( flow_control                         )
  );
 
  assign master_control_o.descriptor   = descriptor_i;
  assign master_control_o.flow_control = flow_control;              
  assign control_state_o               = flow_control;

endmodule

  
