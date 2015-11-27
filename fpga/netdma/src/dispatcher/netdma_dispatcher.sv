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
  This module is one of three major parts of the dma controller. It provides the
  API for a host processor (access trough netdma_cpu_interface to control-status 
  registers, descriptor buffers, rx report buffers), contains main coltroller
  authomatics that drive readmaster and writemaster. The module do not
  contain any RTL logic itself, it contain just submodule instances in
  conditional generation blocks and some wires between them. 
  Submosule hierarhy

  1.0 -- Initial release

*/

module netdma_dispatcher #(
  
  parameter                                TX_ENABLE               = 1,

  parameter                                RX_ENABLE               = 1,
   
  parameter                                DESC_FIFO_DEPTH         = 64,

  parameter                                RX_RESPONSE_FIFO_DEPTH  = 64,

  parameter                                LATCH_IRQ_STATUS_ENABLE = 0
  )
 (
  input                                    clk_i,

  input                                    rst_i,
 
  output                                   host_reset_o,

  // <--> readmaster

  input  netdma_pkg::master_response_t     tx_master_response_i,

  output netdma_pkg::master_control_t      tx_master_control_o,

  // <--> writemaster       
  
  input  netdma_pkg::master_response_t     rx_master_response_i,

  output netdma_pkg::master_control_t      rx_master_control_o,

  // <--> cpu
  netdma_cpu_interface.device              cpu_if
  );
  
  /****************************************************************************/
 
  localparam READ_CONTROL  = 0; 
  localparam WRITE_CONTROL = 1; 

  import netdma_pkg::*;

  // read control <--> csr
  tx_report_t            tx_report;
  logic [1:0]            tx_control_state;

  // write control <--> csr
  rx_report_t            rx_report;
  logic [1:0]            rx_control_state;

  // csr <--> descriptor buffers
  logic                 tx_desc_buff_full;
  logic                 rx_desc_buff_full;

  netdma_csr #( 
    .RX_ENABLE                          ( RX_ENABLE                           ),
    .RX_RESPONSE_FIFO_DEPTH             ( RX_RESPONSE_FIFO_DEPTH              ),
    .LATCH_IRQ_STATUS_ENABLE            ( LATCH_IRQ_STATUS_ENABLE             )
  ) csr (
    .clk_i                              ( clk_i                               ),
    .rst_i                              ( rst_i                               ),
    .host_reset_o                       ( host_reset_o                        ),
    // <--> cpu
    .cpu_if                             ( cpu_if                              ),    
    // <--> read_control
    .tx_report_i                        ( tx_report                           ),
    .tx_control_state_i                 ( tx_control_state                    ),
    // <--> write_control
    .rx_report_i                        ( rx_report                           ),
    .rx_control_state_i                 ( rx_control_state                    ),
    // <--> descriptors_buffer
    .tx_desc_buff_full_i                ( tx_desc_buff_full                   ),
    .rx_desc_buff_full_i                ( rx_desc_buff_full                   )
    );
    
  /****************************************************************************/
  generate
    if( TX_ENABLE )
      begin : gen_tx_control 
        // read control <--> descriptor buffers
        logic [63:0]          tx_descriptor;
        logic                 tx_desc_buf_empty;
        logic                 tx_desc_buf_rdreq;

        netdma_descriptor_buffer  #(
          .DESC_FIFO_DEPTH              ( DESC_FIFO_DEPTH                     )
        ) tx_desc_buf (
          .clk_i                        ( clk_i                               ),
          .rst_i                        ( rst_i                               ),
          // <--> cpu
          .write_i                      ( cpu_if.write_desc_tx                ),
          .writedata_i                  ( cpu_if.writedata                    ),
          // <--> read_control
          .descriptor_o                 ( tx_descriptor                       ),
          .desc_buf_empty_o             ( tx_desc_buf_empty                   ),
          .desc_buf_rdreq_i             ( tx_desc_buf_rdreq                   ),
          // <--> csr
          .desc_buff_full_o             ( tx_desc_buff_full                   )
        );

        netdma_control #(
          .MODE                         ( READ_CONTROL                        )
        ) rd_ctrl (
          .clk_i                        ( clk_i                               ),
          .rst_i                        ( rst_i                               ), 
          // <--> csr
          .control_state_o              ( tx_control_state                    ),
          .report_o                     ( tx_report                           ),
          // <--> descriptor_buffer
          .descriptor_i                 ( tx_descriptor                       ),
          .fifo_empty_i                 ( tx_desc_buf_empty                   ),
          .fifo_rdreq_o                 ( tx_desc_buf_rdreq                   ), 
          // <--> read_master
          .master_response_i            ( tx_master_response_i                ),
          .master_control_o             ( tx_master_control_o                 )
          );

      end : gen_tx_control
  endgenerate

  /****************************************************************************/

  generate
    if( RX_ENABLE )
      begin : gen_rx_control
        // write control <--> descriptor buffers
        logic [63:0]          rx_descriptor;
        logic                 rx_desc_buf_empty;
        logic                 rx_desc_buf_rdreq;

        netdma_descriptor_buffer  #(
          .DESC_FIFO_DEPTH              ( DESC_FIFO_DEPTH                     )
          ) rx_desc_buf (
          .clk_i                        ( clk_i                               ),
          .rst_i                        ( rst_i                               ),
          // <--> cpu
          .write_i                      ( cpu_if.write_desc_rx                ),
          .writedata_i                  ( cpu_if.writedata                    ),
          // <--> write_control
          .descriptor_o                 ( rx_descriptor                       ),
          .desc_buf_empty_o             ( rx_desc_buf_empty                   ),
          .desc_buf_rdreq_i             ( rx_desc_buf_rdreq                   ),
          // <--> csr
          .desc_buff_full_o             ( rx_desc_buff_full                   )
        );

        netdma_control #(
          .MODE                         ( WRITE_CONTROL                       )
        ) wr_ctrl (
          .clk_i                        ( clk_i                               ),
          .rst_i                        ( rst_i                               ), 
          // <--> csr
          .control_state_o              ( rx_control_state                    ),
          .report_o                     ( rx_report                           ),
          // <--> descriptors_block
          .descriptor_i                 ( rx_descriptor                       ),
          .fifo_empty_i                 ( rx_desc_buf_empty                   ),
          .fifo_rdreq_o                 ( rx_desc_buf_rdreq                   ), 
          // <--> write_master
          .master_response_i            ( rx_master_response_i                ),
          .master_control_o             ( rx_master_control_o                 )
          );
      end : gen_rx_control
  endgenerate
endmodule


