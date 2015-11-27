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
  This module is used to receive and store descriptors. By current release it
  designed to receive 32-bit data from system interconnect and have one step
  deserializing schrme to push into the buffer packed descriptors (64 bit).  
 
   1.0 -- Initial release

*/


module netdma_descriptor_buffer #(

  parameter                            DESC_FIFO_DEPTH  = 64
  )  
  (
  input                                clk_i,
  
  input                                rst_i,
  // <--> hps
  input                                write_i,

  input  [31:0]                        writedata_i,
  // <--> read_control
  output [63:0]                        descriptor_o,
  
  output                               desc_buf_empty_o,
 
  input                                desc_buf_rdreq_i,  
  // <--> csr    
  output                               desc_buff_full_o
  ); 

  import netdma_pkg::*;

  // A litle fsm just to make design clearer. Mean "in waiting for..." before
  // labels 
  enum logic {
    FIRST_HALF_S,
    SECOND_HALF_S
  } state;

  always_ff @(posedge clk_i, posedge rst_i)
    if( rst_i )
      state <= FIRST_HALF_S;
    else
      unique case( state )
        FIRST_HALF_S  : if( write_i ) state <= SECOND_HALF_S;
        SECOND_HALF_S : if( write_i ) state <= FIRST_HALF_S;
      endcase

  logic [31:0] address_field;

  always_ff @(posedge clk_i, posedge rst_i)
    if( rst_i )
      address_field <= '0;
    else
      if( write_i & ( state == FIRST_HALF_S ) )
        address_field <= writedata_i;

  // if the second half comes, push whole descriptor into the fifo
  logic  wrreq;
  assign wrreq = ( state == SECOND_HALF_S ) & write_i;

  control_field_t control_field;
  always_comb
    begin  
      control_field    = writedata_i;
      control_field.go = 1'b1;
    end

  logic [63:0] writedata;
  assign writedata = {control_field, address_field}; 
   
   
  fifo_showahead #(
    .WIDTH                              ( 64                         ),
    .DEPTH                              ( DESC_FIFO_DEPTH            )
 )desc_fifo  (
    .aclr                               ( rst_i                      ),
    .clock                              ( clk_i                      ),
    .data                               ( writedata                  ),
    .rdreq                              ( desc_buf_rdreq_i           ),
    .wrreq                              ( wrreq                      ),
    .almost_full                        (                            ),
    .empty                              ( desc_buf_empty_o           ),
    .full                               ( desc_buff_full_o           ),
    .q                                  ( descriptor_o               )
  );
  defparam desc_fifo.scfifo_component.lpm_widthu = $clog2( DESC_FIFO_DEPTH );
  defparam desc_fifo.scfifo_component.almost_full_value =  DESC_FIFO_DEPTH;
  
endmodule    
 




