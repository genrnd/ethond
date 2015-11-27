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
  This file contains typedefs for most significant data strucrure types
  in netdma, include control-status registers, descriptor and more.
  netdma_pkg package with this typedefs should be imported into
  each module in design that uses this typedefs.

  1.0 -- Initial release

  */

package netdma_pkg;
  
  // type describes 32 bit descriptor control field
  typedef struct packed {
    logic [15:0]  bytecount;                    //31:16
    logic [7:0]   sequence_number;              //15:8
    logic [1:0]   not_used;                     //7:6
    logic         stop_on_error;		//5
    logic         disable_tx_irq;	        //4
    logic         disable_rx_irq; 		//3
    logic [1:0]   desc_type;			//2:1
    logic         go;				//0
  } control_field_t;
   
  // Type describes 64 bit descriptor both read and write types
  typedef struct packed {
    control_field_t control_field;              // 0x1
    logic [31:0] address;                       // 0x0
  } descriptor_t;
  

  // Type describes a wire group from a netdma_control module to
  // a readmaster/writemaster module. Merely for convenience.
  typedef struct packed {
     descriptor_t       descriptor;
     logic [1:0]        flow_control;
  } master_control_t;


  // Type describes a wire group from a readmaster/writemaster module to
  // a netdma_control module. Merely for convenience.
  typedef struct packed {
    logic [15:0] bytecount;
    logic        error;
    logic        eop;
  } master_response_t;
  
 
  // Type describes a wire group
  typedef struct packed {
    logic [15:0]        bytecount;
    logic [7:0]         sequence_number;
    logic [4:0]         not_used;      
    logic               error; 
    logic               disable_irq;
    logic               is_report;
   } rx_report_t;
  
  typedef struct packed {
    //logic [20:0]        not_used;
    logic [7:0]         sequence_number;
    logic               error;
    logic               disable_irq;
    logic               is_report;
   } tx_report_t; 
   
  
  // Type describes the control register content. If you modify this structure,
  // don't forget to do corresponding changes in your driver.
  typedef struct packed {
    logic            clear_tx_irq_pending;
    logic            clear_rx_irq_pending;
    logic            clear_tx_irq_status;
    logic            clear_rx_irq_status;
    logic            tx_irq_enable;
    logic            rx_irq_enable;
    logic            reset;
  
  } control_reg_t;

  // if you have modified control_reg_t structue, don't forget to set here new
  // actual width
  parameter CONTROL_REG_WIDTH = 7;
  
  // Type describes the status register content. If you modify this structure,
  // don't forget to do corresponding changes in your driver. 
  typedef struct packed {
   // logic [11:0]     not_used;              // 31:20
  
    logic            disable_tx_irq;        // 21
    logic            disable_rx_irq;        // 20
  
    logic [7:0]      tx_last_seq_number;    // 19:12
    logic            tx_with_errors;        // 11
    logic            tx_is_any_done;        // 10
  
    logic            rx_report_buf_empty;   // 9
   
    logic [1:0]      tx_control_state;      // 8:7
    logic [1:0]      rx_control_state;      // 6:5
  
    logic            tx_desc_buf_full;      // 4
    logic            rx_desc_buf_full;      // 3
  
    logic            tx_irq_pending;        // 2
    logic            rx_irq_pending;        // 1
  
    logic            reset_state;           // 0
  
  } status_reg_t;
   
  // if you have modified status_reg_t structue, don't forget to set here new
  // actual width
  parameter  STATUS_REG_WIDTH = 22;
  
  // bind control and status registers together
  typedef struct packed {
    status_reg_t     status; // 0x1
    control_reg_t    ctrl;   // 0x0
  } csr_t;
 
endpackage


