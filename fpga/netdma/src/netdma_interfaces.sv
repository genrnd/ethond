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
  along with Netdma ip core.  If not, see <http://www.gnu.org/licenses/>.
*/
/*
  Author: Dmitry Hodyrev d.hodyrev@metrotek.spb.ru 
  Date: 22.10.2015
*/
/*
  This file contains netdma interfaces that are a little more than just
  wire collections to provide more compact empedding into system level design
  and simplify internal interconnect. All interfaces together with corresponding 
  endpoint logic inside netdma meets Altera avalon interface specifications. 
  Also have facilities to convenient using in OOP testbench. 
  See details in documentation and per-interface comments. 

  1.0 -- Initial release

  */

`ifndef NETDMA_IFS_DEF_DONE
`define NETDMA_IFS_DEF_DONE

`include "./netdma.sv"

/*
  This slave interface together with corresponding endpoint logic inside
  dispatcher/netdma_csr.sv and dispatcher/netdma_descriptor_buffer.sv
  meets Altera Avalon memory mapped interface specification (exept irq signals)
  and contains a set of wires to respond fundamental read transaction requests
  from a system interconnect. 
  It provides all dma controller <--> cpu communications --
  control-status registers reading/writing, reading rx reports and writing
  descrioptors. It also takes on some address resolution functions to 
  simplify RTL design and avoid writedata multiplexing  
*/

interface netdma_cpu_interface
//synopsys translate_off
( input clk )
//synopsys translate_on
  ;
  logic [12:0]                     address;
  logic                            write;
  logic [31:0]                     writedata;
  logic                            read;
  logic [31:0]                     readdata;
  logic                            readdatavalid;
  logic                            tx_irq;
  logic                            rx_irq;
  logic                            waitrequest;

  assign readdatavalid = read;

  logic  write_desc_tx;
  assign write_desc_tx = ( address == `NETDMA_TX_DESC_BUF_ADDR ) ? write : '0;

  logic  write_desc_rx;
  assign write_desc_rx = ( address == `NETDMA_RX_DESC_BUF_ADDR ) ? write : '0;

  modport device (input  address, write, write_desc_tx, write_desc_rx,
                         writedata, read,
                  output readdata, tx_irq, rx_irq, waitrequest);

//synopsys translate_off

  clocking cb @( posedge clk );
    input readdata, tx_irq, rx_irq, waitrequest;
    output address, write, writedata, read;
  endclocking

  modport test ( clocking cb );
//synopsys translate_on
endinterface

/************************DATA TRANSFER RELATED INTERFACES************************/
/*
  This master interface together with corresponding endpoint logic inside
  readmaster/netdma_mm2st.sv meets Altera Avalon memory mapped interface 
  specification and contains a set of wires to initiate fundamental read 
  transactions and get pipeplined interconnect response
 */

interface netdma_mm_read_interface #(
    parameter                           DATA_WIDTH = 64
    )
//synopsys translate_off
( input clk )
//synopsys translate_on
  ;
  /*external*/
  logic [31:0]              address;
  logic [DATA_WIDTH-1:0]    readdata;
  logic                     read;
  logic                     readdatavalid;
  logic                     waitrequest;



  modport master ( input  readdata, waitrequest, readdatavalid,
                   output address, read );

//synopsys translate_off
 
  clocking cb @( posedge clk );
    input  address, read;
    output readdata, waitrequest, readdatavalid;
  endclocking

  modport test (clocking cb,
                input address, read,
                output readdata, readdatavalid, waitrequest);
//synopsys translate_on
endinterface

/************************************************************************/
/*
  This master interface together with corresponding endpoint logic inside
  writemaster/netdma_st2mm.sv meets Altera Avalon memory mapped interface 
  specification and contains a set of wires to initiate fundamental write
  transactions.
 */
interface netdma_mm_write_interface #(
    parameter                           DATA_WIDTH = 64
    )
//synopsys translate_off
( input clk )
//synopsys translate_on
  ;

  logic [31:0]              address;
  logic [DATA_WIDTH-1:0]    writedata;
  logic                     write;
  logic                     waitrequest;

  modport master ( input  waitrequest,
                   output address, write, writedata );

//synopsys translate_off

  clocking cb @( posedge clk );
    input  address, write, writedata;
    output waitrequest;
  endclocking

  modport test (clocking cb,
                input address, write, writedata,
                output waitrequest);
//synopsys translate_on
endinterface

/************************************************************************/
/*
  This source interface together with corresponding endpoint logic inside
  readmaster/netdma_mm2st.sv meets Altera Avalon streaming interface 
  specification and contains a set of wires to transfer packet data to a 
  streaming sink
*/
interface netdma_src_interface #(
    parameter                           DATA_WIDTH = 64
    )
//synopsys translate_off
( input clk )
//synopsys translate_on
  ;

  localparam EMPTY_WIDTH = $clog2( DATA_WIDTH / 8 );

  logic                     ready;
  logic                     valid;
  logic [DATA_WIDTH-1:0]    data;
  logic                     startofpacket;
  logic                     endofpacket;
  logic [EMPTY_WIDTH-1:0]   empty;

  modport master (input  ready, 
                  output data, valid, 
                         startofpacket, endofpacket, empty);


//synopsys translate_off

  clocking cb @( posedge clk );
    input  data, valid, startofpacket, endofpacket, empty;
    output ready;
  endclocking

  modport test (clocking cb);
//synopsys translate_on
endinterface


/********************************************************************/
/*
  This sink interface together with corresponding endpoint logic inside
  writemaster/netdma_st2mm.sv meets Altera Avalon streaming interface 
  specification and contains a set of wires to receive packet data from a 
  streaming source
*/
interface netdma_snk_interface #(
  parameter DATA_WIDTH                          = 64 
  )
//synopsys translate_off 
  ( input clk )
//synopsys translate_on 
  ;

  localparam EMPTY_WIDTH = $clog2( DATA_WIDTH / 8 );

  logic                     ready;
  logic                     valid;
  logic [DATA_WIDTH-1:0]    data;
  logic                     startofpacket;
  logic                     endofpacket;
  logic [EMPTY_WIDTH-1:0]   empty;
  logic                     error;


  modport master (input  data, valid, startofpacket, 
                         endofpacket, error, empty,
                  output ready);


//synopsys translate_off
 
  clocking cb @( posedge clk );
    input   ready;
    output  data, valid, startofpacket, endofpacket, error, empty;
  endclocking

  modport test (clocking cb,
                input ready,
                output data, valid, startofpacket, endofpacket,
                error, empty);
//synopsys translate_on
endinterface

//synopsys translate_off
/*vinterface for a virtual interface*/
typedef virtual netdma_cpu_interface.test         cpu_vinterface;
typedef virtual netdma_mm_read_interface.test     mm_read_vinterface; 
typedef virtual netdma_mm_write_interface.test    mm_write_vinterface; 
typedef virtual netdma_src_interface.test         src_vinterface; 
typedef virtual netdma_snk_interface.test         snk_vinterface; 
//synopsys translate_on

`endif
