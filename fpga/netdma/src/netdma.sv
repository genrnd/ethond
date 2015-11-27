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
  This is the top level of Netdma ip core. It takes clocking, interfaces and
  parameters from system level design and instantiates three main parts of the
  dma controller (dispatcher, readmaster, writemaster), or less, if rx or tx
  features disabled. It't doesn't contain combinational or synchronous logic
  itself, just some wires between instantiated submodules and conditional
  generation blocks. An example of instantiation of this module with
  breif parameter usage see in "instance example".

  1.0 -- Initial release

  */
 
`ifndef NETDMA_DEF
`define NETDMA_DEF

`define NETDMA_CONTROL_REG_ADDR        5'h0
`define NETDMA_STATUS_REG_ADDR         5'h4
`define NETDMA_REPORT_REG_ADDR         5'h8
`define NETDMA_TX_DESC_BUF_ADDR        5'hc
`define NETDMA_RX_DESC_BUF_ADDR        5'h10

module netdma #(

  parameter                            TX_ENABLE                    = 1,

  parameter                            RX_ENABLE                    = 1,

  parameter                            DATA_WIDTH                   = 64,

  parameter                            DESC_FIFO_DEPTH              = 64,

  parameter                            RX_RESPONSE_FIFO_DEPTH       = 64,

  parameter                            LATCH_IRQ_STATUS_ENABLE      = 0,
  
  parameter                            TX_FIFO_DEPTH                = 64,

  parameter                            TX_MM_IF_MAX_PENDING_COUNT   = 1,

  parameter                            TX_BYTES_REORDER_ENABLE      = 0,

  parameter                            TX_UNALIGNED_ACCESS_ENABLE   = 1,
  
  parameter                            RX_BYTES_REORDER_ENABLE      = 0,

  parameter                            WORD_ADDRESSING              = 1
  )
 (
  input                                clk_i,
  
  input                                rst_i,

  netdma_cpu_interface.device          cpu_if,
  
  netdma_mm_read_interface.master      mm_read_if,
  
  netdma_mm_write_interface.master     mm_write_if,
  
  netdma_src_interface.master          src_if,
  
  netdma_snk_interface.master          snk_if  
);

  import netdma_pkg::*;

  logic host_reset;
  logic rst;

  always_comb
    begin
      rst = host_reset;
      //synopsys translate_off
      rst = rst | rst_i;      //by now async reset enable only 4 verification purps
      //synopsys translate_on
    end
  
  master_response_t rx_master_response, tx_master_response;
  master_control_t  rx_master_control,  tx_master_control;

  netdma_dispatcher #(
    .TX_ENABLE                             ( TX_ENABLE                        ),
    .RX_ENABLE                             ( RX_ENABLE                        ),
    .DESC_FIFO_DEPTH                       ( DESC_FIFO_DEPTH                  ),
    .RX_RESPONSE_FIFO_DEPTH                ( RX_RESPONSE_FIFO_DEPTH           ),
    .LATCH_IRQ_STATUS_ENABLE               ( LATCH_IRQ_STATUS_ENABLE          )
    )disp(
    .clk_i                                 ( clk_i                            ),
    .rst_i                                 ( rst                              ),
    .host_reset_o                          ( host_reset                       ),
    .tx_master_response_i                  ( tx_master_response               ),
    .tx_master_control_o                   ( tx_master_control                ),
    .rx_master_response_i                  ( rx_master_response               ),
    .rx_master_control_o                   ( rx_master_control                ),
    .cpu_if                                ( cpu_if                           )
  );

  generate 
    if( TX_ENABLE )
      begin : gen_rm
        netdma_readmaster #(
          .DATA_WIDTH                      ( DATA_WIDTH                       ),
          .FIFO_DEPTH                      ( TX_FIFO_DEPTH                    ),
          .FIFO_ALMOST_FULL_VALUE          ( TX_FIFO_DEPTH - 
                                             TX_MM_IF_MAX_PENDING_COUNT - 1   ),
          .BYTES_REORDER_ENABLE            ( TX_BYTES_REORDER_ENABLE          ),
          .UNALIGNED_ACCESS_ENABLE         ( TX_UNALIGNED_ACCESS_ENABLE       ),
          .WORD_ADDRESSING                 ( WORD_ADDRESSING                  )
        ) rm (
          .clk_i                           ( clk_i                            ),
          .rst_i                           ( rst                              ),
          .master_control_i                ( tx_master_control                ),
          .master_response_o               ( tx_master_response               ),
          .mm_read_if                      ( mm_read_if                       ),
          .src_if                          ( src_if                           )
        );
    end : gen_rm
  endgenerate

  generate
    if( RX_ENABLE )
      begin : gen_wm
        netdma_writemaster #( 
         .DATA_WIDTH                       ( DATA_WIDTH                       ), 
         .BYTES_REORDER_ENABLE             ( RX_BYTES_REORDER_ENABLE          ), 
         .WORD_ADDRESSING                  ( WORD_ADDRESSING                  )
       ) wm (
         .clk_i                            ( clk_i                            ),
         .rst_i                            ( rst                              ),
         .master_control_i                 ( rx_master_control                ),
         .master_response_o                ( rx_master_response               ),
         .mm_write_if                      ( mm_write_if                      ),
         .snk_if                           ( snk_if                           )
        );
     end : gen_wm
   endgenerate
    
endmodule
`endif
