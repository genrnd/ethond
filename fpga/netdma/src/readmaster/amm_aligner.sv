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
  This module is responsible for data aligning on a pipligned memory mapped
  interface being embedded on the path of readdata and readdatavalid signal.
  Actualy, it works as a datastream processing scheme, but without backpressure
  (always ready). It introduces a one tact delay. Module drivig expample:

  input offset = 1 :
  [b7 b6 b5 b4 b3 b2 b1 b0] // 1st readdata_i
  [a7 a6 a5 a4 a3 a2 a1 a0] // 2nd readdata_i
  -------------------------
  [b0 a7 a6 a5 a4 a3 a2 a1] // readdata_o 
             
  input offset = 7 :
  [b7 b6 b5 b4 b3 b2 b1 b0] // 1st readdata_i
  [a7 a6 a5 a4 a3 a2 a1 a0] // 2nd readdata_i
  -------------------------
  [b6 b5 b4 b3 b2 b1 b0 a7] // readdata_o

  and so on...

  Tip:
  When using this module on memory mapped interface, don't forget to do one more
  read request than the count of words you actualy need.
   
  1.0 -- Initial release

*/



module amm_data_aligner #(
  DATA_WIDTH                          = 64
)(

  // basic/control
  
  input                                 clk_i,

  input                                 rst_i,

  input                                 run_i,

  input [($clog2(DATA_WIDTH / 8))-1:0] offset_i,

  // data io

  input [DATA_WIDTH-1:0]                readdata_i, 

  input                                 readdatavalid_i,

  output [DATA_WIDTH-1:0]               readdata_o,

  output                                readdatavalid_o
);

  localparam BYTE_NUM = DATA_WIDTH / 8;

  logic [DATA_WIDTH-1:0] readdata_d1_reg;
  logic readdata_d1_ena;

  always_ff @( posedge clk_i, posedge rst_i )
    if( rst_i ) 
      readdata_d1_reg <= '0;
    else
      if( readdata_d1_ena )
        readdata_d1_reg <= readdata_i;

  assign readdata_d1_ena = readdatavalid_i & run_i;

  /***************************************************************************/
  // a very primitive state machine 
  typedef enum logic {
    EMPTY_S,
    KEEP_1ST_PART
  } aligner_fsm_t;

  aligner_fsm_t state, state_next;

  always_ff @( posedge clk_i, posedge rst_i )
    if( rst_i ) 
      state <= EMPTY_S;
    else
      if( ~run_i )
        state <= EMPTY_S;
      else
        if( readdatavalid_i )
        state <= KEEP_1ST_PART;


  assign readdatavalid_o = ( state == KEEP_1ST_PART ) & readdata_d1_ena;

  // select needful bytes to output

  logic [DATA_WIDTH-1:0] barrelshifter_input_A [0:BYTE_NUM-1];
  logic [DATA_WIDTH-1:0] barrelshifter_input_B [0:BYTE_NUM-1];
  logic [DATA_WIDTH-1:0] barrelshifter_A;
  logic [DATA_WIDTH-1:0] barrelshifter_B;

  generate
    genvar i;
    for(i = 0; i < (BYTE_NUM-1); i++ )
    begin:  barrel_shifter_inputs
      assign barrelshifter_input_A[i] = readdata_i << (8 * (BYTE_NUM - i)); 
      assign barrelshifter_input_B[i] = readdata_d1_reg >> (8 * i);
    end
  endgenerate

  assign barrelshifter_A = barrelshifter_input_A[offset_i];   // upper portion of the packed word
  assign barrelshifter_B = barrelshifter_input_B[offset_i];   // lower portion of the packed word
  assign readdata_o      = (barrelshifter_A | barrelshifter_B);


endmodule 






