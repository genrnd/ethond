//////////////////////////////////////////////////////////////////////
////                                                              ////
////  File name "defines.vh"                                       ////
////                                                              ////
////  This file is part of the "10GE MAC" project                 ////
////  http://www.opencores.org/cores/xge_mac/                     ////
////                                                              ////
////  Author(s):                                                  ////
////      - A. Tanguay (antanguay@opencores.org)                  ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2008 AUTHORS. All rights reserved.             ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////


// Ethernet codes

`define IDLE       8'h07
`define PREAMBLE   8'h55
`define SEQUENCE   8'h9c
`define SFD        8'hd5
`define START      8'hfb
`define TERMINATE  8'hfd 	
`define ERROR      8'hfe



`define LINK_FAULT_OK      2'd0
`define LINK_FAULT_LOCAL   2'd1
`define LINK_FAULT_REMOTE  2'd2

`define FAULT_SEQ_LOCAL  1'b0
`define FAULT_SEQ_REMOTE 1'b1

`define LOCAL_FAULT   8'd1
`define REMOTE_FAULT  8'd2

`define PAUSE_FRAME   48'h010000c28001

`define LANE0        7:0
`define LANE1       15:8
`define LANE2      23:16
`define LANE3      31:24
`define LANE4      39:32
`define LANE5      47:40
`define LANE6      55:48
`define LANE7      63:56


`define TXSTATUS_NONE       'h0

`define TXSTATUS_MOD        2:0
`define TXSTATUS_PATT_FB    5:3
`define TXSTATUS_EOP        6
`define TXSTATUS_SOP        7
`define TXSTATUS_PATT_EN    8 
`define TXSTATUS_WIDTH      9


`define RXSTATUS_NONE       8'h0
`define RXSTATUS_EOP        3'd6
`define RXSTATUS_SOP        3'd7



`define RXSTATUS_ERR_CRC         2'd0
`define RXSTATUS_ERR_TOO_LONG    2'd1
`define RXSTATUS_ERR_SOP         2'd2

`define RXSTATUS_MOD        2:0




//
// FIFO Size: 8 * (2^AWIDTH) will be the size in bytes
//            7 --> 128 entries, 1024 bytes for data fifo
//
`define TX_DATA_FIFO_AWIDTH 7
`define RX_DATA_FIFO_AWIDTH 7

//
// FIFO Size: Holding FIFOs are 16 deep
//
`define TX_HOLD_FIFO_AWIDTH 4
`define RX_HOLD_FIFO_AWIDTH 4


// Memory types
`define MEM_AUTO_SMALL      1
`define MEM_AUTO_MEDIUM     2

//Frame size (in bytes) width
`define FRMSIZE_WIDTH       16

`define FRMSIZE_MAX   16'd65000 //(2**(`FRMSIZE_WIDTH) - 1)
`define FRMSIZE_MIN   16'd64 
