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
  This module contains control-status registers, irq generation and sending
  logic, rx report buffer ( because rx reports was initialy conceived as a specal
  form of read-popping status and the output register if the fifo can be
  concidered as a part of control-status registers ). Description of registers
  see in doc/REGMAP

    
  1.0 -- Initial release

*/


`include "../netdma.sv" //for an address macros

module netdma_csr #(

  parameter                           RX_ENABLE                 = 1,

  parameter                           RX_RESPONSE_FIFO_DEPTH    = 64,

  parameter                           LATCH_IRQ_STATUS_ENABLE   = 0
  )
  (
  input                               clk_i,
    
  input                               rst_i,
    
  output                              host_reset_o,
    // <--> cpu
  netdma_cpu_interface.device         cpu_if,
    // <--> read_control
  input netdma_pkg::tx_report_t       tx_report_i,
    
  input [1:0]                         tx_control_state_i,
    // <--> write_control
  input netdma_pkg::rx_report_t       rx_report_i,
   
  input [1:0]                         rx_control_state_i,
    // <--> descriptors_buffer
  input                               tx_desc_buff_full_i,
    
  input                               rx_desc_buff_full_i
  );
    
  import netdma_pkg::*;

  csr_t csr, csr_next;

  rx_report_t rx_report;

  initial begin
    csr = '0;
  end

  always_ff @(posedge clk_i)
    begin 
      if( cpu_if.write & ( cpu_if.address==`NETDMA_CONTROL_REG_ADDR ) ) 
        csr.ctrl <= cpu_if.writedata[6:0];
      //self cleared bits
      if( csr.ctrl.clear_tx_irq_status )
        csr.ctrl.clear_tx_irq_status <= '0;
      if( csr.ctrl.clear_rx_irq_status )
        csr.ctrl.clear_rx_irq_status <= '0;
    end


  always_ff @( posedge clk_i )
    if( rst_i )
      begin  
        csr.status             <= '0;
        csr.status.reset_state <= '1;
      end
    else
      begin  
        csr.status             <= csr_next.status;
        csr.status.reset_state <= '0;
      end

  always_comb 
    begin : READ_LOGIC
      cpu_if.readdata = '0;
       if( cpu_if.read )
        case( cpu_if.address )
          `NETDMA_STATUS_REG_ADDR : 
                cpu_if.readdata[STATUS_REG_WIDTH-1:0] = csr.status; 
          `NETDMA_REPORT_REG_ADDR : 
                cpu_if.readdata[31:0] = rx_report;
          default : 
                cpu_if.readdata[CONTROL_REG_WIDTH-1:0] = csr.ctrl;
        endcase
  end : READ_LOGIC

  logic fifo_empty;

  logic  rx_report_availabe;
  assign rx_report_availabe = (~fifo_empty & rx_report.is_report);
  

  logic tx_irq_event, rx_irq_event;
  posedge_detector tx_event_posedge_detector ( clk_i,, tx_report_i.is_report, tx_irq_event );
  posedge_detector rx_event_posedge_detector ( clk_i,, rx_report_availabe,    rx_irq_event );

  logic tx_irq_enable, rx_irq_enable;
  assign tx_irq_enable = csr.ctrl.tx_irq_enable & ~csr.status.disable_tx_irq;
  assign rx_irq_enable = csr.ctrl.rx_irq_enable & ~rx_report.disable_irq;


  always_comb
    begin : STATUS_REG
      csr_next.status.tx_desc_buf_full      = tx_desc_buff_full_i;
      csr_next.status.rx_desc_buf_full      = rx_desc_buff_full_i;
      csr_next.status.tx_control_state      = tx_control_state_i;
      csr_next.status.rx_control_state      = rx_control_state_i;
      csr_next.status.rx_report_buf_empty   = fifo_empty;

      if (tx_report_i.is_report)
        begin
          csr_next.status.tx_is_any_done     = '1;
          csr_next.status.tx_with_errors     = tx_report_i.error;
          csr_next.status.tx_last_seq_number = tx_report_i.sequence_number;
          csr_next.status.disable_tx_irq     = tx_report_i.disable_irq;
        end
      else
        begin
          csr_next.status.tx_is_any_done     = csr.status.tx_is_any_done;
          csr_next.status.tx_with_errors     = csr.status.tx_with_errors; 
          csr_next.status.tx_last_seq_number = csr.status.tx_last_seq_number;
          csr_next.status.disable_tx_irq     = csr.status.disable_tx_irq; 
        end
      
      // non-oblivious scheme just to play with combinatorics. May be rewritten
      // later for more readable  
      csr_next.status.tx_irq_pending = ~csr.ctrl.clear_tx_irq_pending 
                                     & ~tx_irq_enable
                                     & (tx_irq_event | csr.status.tx_irq_pending);
         
      csr_next.status.rx_irq_pending = ~csr.ctrl.clear_rx_irq_pending 
                                     & ~rx_irq_enable 
                                     & (rx_irq_event | csr.status.rx_irq_pending);
     
    end : STATUS_REG

  // this signal goes up on hierarchy 
  assign host_reset_o              = csr.ctrl.reset;
  assign cpu_if.waitrequest = csr.status.reset_state;

  // pop a rx report when reading it
  logic  fifo_rdreq;
  assign fifo_rdreq = cpu_if.read & ( cpu_if.address==`NETDMA_REPORT_REG_ADDR); 


  // this generate block will made irq request signal that rises up after 
  // it's event and then keeps on until it be cleared by a driver, or will
  // make irq event signal as a strobe after it's event in dependency of the
  // parameter 

  generate
    if( LATCH_IRQ_STATUS_ENABLE )
      begin : latch_irq_status
        logic set_tx_irq, set_rx_irq;
        assign set_tx_irq = tx_irq_enable & 
                (tx_irq_event | csr.status.tx_irq_pending);
        assign set_rx_irq = rx_irq_enable & 
                (rx_irq_event | csr.status.rx_irq_pending);

        logic clear_tx_irq, clear_rx_irq;
        assign clear_tx_irq = csr.ctrl.clear_tx_irq_status;
        assign clear_rx_irq = csr.ctrl.clear_rx_irq_status;

        irq_sender tx_irq_sender(
          .clk_i                     ( clk_i                      ),     
          .rst_i                     ( rst_i                      ),     
          .set_irq_i                 ( set_tx_irq                 ),     
          .clear_irq_i               ( clear_tx_irq               ),     
          .irq_o                     ( cpu_if.tx_irq            )
       );    

        irq_sender rx_irq_sender(
          .clk_i                     ( clk_i                      ),     
          .rst_i                     ( rst_i                      ),     
          .set_irq_i                 ( set_rx_irq                 ),     
          .clear_irq_i               ( clear_rx_irq               ),     
          .irq_o                     ( cpu_if.rx_irq            )
        );    
      end : latch_irq_status
    else
      begin : strobe_irq_status       
        assign cpu_if.tx_irq = tx_irq_enable & 
                (tx_irq_event | csr.status.tx_irq_pending);
        assign cpu_if.rx_irq = rx_irq_enable & 
                (rx_irq_event | csr.status.rx_irq_pending);
      end : strobe_irq_status
  endgenerate

  generate
    if( RX_ENABLE )
      begin : rx_response_buffer
        fifo_showahead #(
          .WIDTH                    ( 32                         ),
          .DEPTH                    ( RX_RESPONSE_FIFO_DEPTH     ))
        report_buffer (
          .aclr                     ( rst_i                      ),
          .clock                    ( clk_i                      ),
          .data                     ( rx_report_i                ),
          .rdreq                    ( fifo_rdreq                 ),
          .wrreq                    ( rx_report_i.is_report      ),
          .almost_full              (                            ),
          .empty                    ( fifo_empty                 ),
          .full	       	            (                            ),
          .q                        ( rx_report                  )
        );
        defparam report_buffer.scfifo_component.lpm_widthu = $clog2( RX_RESPONSE_FIFO_DEPTH );
        defparam report_buffer.scfifo_component.almost_full_value = RX_RESPONSE_FIFO_DEPTH;
      end : rx_response_buffer
  endgenerate

endmodule


