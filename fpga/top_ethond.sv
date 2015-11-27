/*
  Legal Notice: Copyright 2015 STC Metrotek.

  This file is part of the EthOnd BSP.

  EthOnd BSP is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  EthOnd BSP is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with EthOnd BSP. If not, see <http://www.gnu.org/licenses/>.
*/


module top_ethond(
                input              trg_clk125m_i [1:0],

                input              trg_rx_clk_i [1:0],
                input   [3:0]      trg_rxd_i [1:0],
                input              trg_rx_ctrl_i [1:0],

                output             trg_tx_clk_o [1:0],
                output  [3:0]      trg_txd_o [1:0],
                output             trg_tx_ctrl_o [1:0],

                output             trg_mdc_o [1:0], 
                inout              trg_mdio_io [1:0], 
                output             trg_nreset_o [1:0],

                output             trg_ptpclk_o [1:0],
                input              trg_ptp_int [1:0], 
                inout              trg_ptp_io [1:0],

                input              clk_25m_i,

                output wire [14:0] memory_mem_a,                   
                output wire [2:0]  memory_mem_ba,                  
                output wire        memory_mem_ck,                  
                output wire        memory_mem_ck_n,                
                output wire        memory_mem_cke,                 
                output wire        memory_mem_cs_n,                
                output wire        memory_mem_ras_n,               
                output wire        memory_mem_cas_n,               
                output wire        memory_mem_we_n,                
                output wire        memory_mem_reset_n,             
                inout  wire [31:0] memory_mem_dq,                  
                inout  wire [3:0]  memory_mem_dqs,                 
                inout  wire [3:0]  memory_mem_dqs_n,               
                output wire        memory_mem_odt,                 
                output wire [3:0]  memory_mem_dm,                  
                input  wire        memory_oct_rzqin,              

                output wire        hps_io_hps_io_emac1_inst_TX_CLK,     
                output wire        hps_io_hps_io_emac1_inst_TXD0,       
                output wire        hps_io_hps_io_emac1_inst_TXD1,       
                output wire        hps_io_hps_io_emac1_inst_TXD2,       
                output wire        hps_io_hps_io_emac1_inst_TXD3,       
                input  wire        hps_io_hps_io_emac1_inst_RXD0,       
                inout  wire        hps_io_hps_io_emac1_inst_MDIO,       
                output wire        hps_io_hps_io_emac1_inst_MDC,        
                input  wire        hps_io_hps_io_emac1_inst_RX_CTL,     
                output wire        hps_io_hps_io_emac1_inst_TX_CTL,     
                input  wire        hps_io_hps_io_emac1_inst_RX_CLK,     
                input  wire        hps_io_hps_io_emac1_inst_RXD1,       
                input  wire        hps_io_hps_io_emac1_inst_RXD2,       
                input  wire        hps_io_hps_io_emac1_inst_RXD3,       
                inout  wire        hps_io_hps_io_qspi_inst_IO0,         
                inout  wire        hps_io_hps_io_qspi_inst_IO1,         
                inout  wire        hps_io_hps_io_qspi_inst_IO2,         
                inout  wire        hps_io_hps_io_qspi_inst_IO3,         
                output wire        hps_io_hps_io_qspi_inst_SS0,         
                output wire        hps_io_hps_io_qspi_inst_CLK,         
                inout  wire        hps_io_hps_io_sdio_inst_CMD,         
                inout  wire        hps_io_hps_io_sdio_inst_D0,          
                inout  wire        hps_io_hps_io_sdio_inst_D1,          
                output wire        hps_io_hps_io_sdio_inst_CLK,         
                inout  wire        hps_io_hps_io_sdio_inst_D2,          
                inout  wire        hps_io_hps_io_sdio_inst_D3,          
                inout  wire        hps_io_hps_io_usb1_inst_D0,          
                inout  wire        hps_io_hps_io_usb1_inst_D1,          
                inout  wire        hps_io_hps_io_usb1_inst_D2,          
                inout  wire        hps_io_hps_io_usb1_inst_D3,          
                inout  wire        hps_io_hps_io_usb1_inst_D4,          
                inout  wire        hps_io_hps_io_usb1_inst_D5,          
                inout  wire        hps_io_hps_io_usb1_inst_D6,          
                inout  wire        hps_io_hps_io_usb1_inst_D7,          
                input  wire        hps_io_hps_io_usb1_inst_CLK,         
                output wire        hps_io_hps_io_usb1_inst_STP,         
                input  wire        hps_io_hps_io_usb1_inst_DIR,         
                input  wire        hps_io_hps_io_usb1_inst_NXT,         
                input  wire        hps_io_hps_io_uart0_inst_RX,         
                output wire        hps_io_hps_io_uart0_inst_TX,         
                inout  wire        hps_io_hps_io_i2c0_inst_SDA,         
                inout  wire        hps_io_hps_io_i2c0_inst_SCL,         
                inout  wire        hps_io_hps_io_gpio_inst_GPIO09,      
                inout  wire        hps_io_hps_io_gpio_inst_GPIO37,      
                inout  wire        hps_io_hps_io_gpio_inst_GPIO44,      
                inout  wire        hps_io_hps_io_gpio_inst_GPIO48,      
                inout  wire        hps_io_hps_io_gpio_inst_GPIO52,      
                inout  wire        hps_io_hps_io_gpio_inst_GPIO65,      
                inout  wire        hps_io_hps_io_gpio_inst_LOANIO58
);

etnsoc_if   etnsoc_if();
m88e1512_if trg_if[1:0]();

netdma_cpu_interface                                 netdma_cpu_if0   ( );
netdma_cpu_interface                                 netdma_cpu_if1   ( );
netdma_mm_write_interface  #( .DATA_WIDTH ( 64 ) )   netdma_write_if0 ( );
netdma_mm_write_interface  #( .DATA_WIDTH ( 64 ) )   netdma_write_if1 ( );
netdma_mm_read_interface   #( .DATA_WIDTH ( 64 ) )   netdma_read_if0  ( );
netdma_mm_read_interface   #( .DATA_WIDTH ( 64 ) )   netdma_read_if1  ( );


logic           clk_125m;
logic           clk_62_5m;
logic           clk_25m;

// 67 HPS pins in Cyclone V HPS
logic [66:0] hps_loan_io_in;                    
logic [66:0] hps_loan_io_out;                    
logic [66:0] hps_loan_io_oe;

logic [31:0] irq0_irq;


soc_ethond soc_ethond(
  .sys_clk_clk                            ( etnsoc_if.soc.clk                                    ),
  .sys_rst_reset                          ( etnsoc_if.soc.rst                                    ),

  .irq0_irq                               ( irq0_irq                                             ),
  .irq1_irq                               ( '0                                                   ),
                         
  .netdma_write0_waitrequest              ( netdma_write_if0.waitrequest                         ),
  .netdma_write0_readdata                 (                                                      ),
  .netdma_write0_readdatavalid            (                                                      ),
  .netdma_write0_burstcount               ( 1'd1                                                 ),
  .netdma_write0_writedata                ( netdma_write_if0.writedata                           ),
  .netdma_write0_address                  ( netdma_write_if0.address                             ),
  .netdma_write0_write                    ( netdma_write_if0.write                               ),
  .netdma_write0_read                     ( '0                                                   ),
  .netdma_write0_byteenable               ( 8'hff                                                ),
  .netdma_write0_debugaccess              ( '0                                                   ),
                           
  .netdma_write1_waitrequest              ( netdma_write_if1.waitrequest                         ),
  .netdma_write1_readdata                 (                                                      ),
  .netdma_write1_readdatavalid            (                                                      ),
  .netdma_write1_burstcount               ( 1'd1                                                 ),
  .netdma_write1_writedata                ( netdma_write_if1.writedata                           ),
  .netdma_write1_address                  ( netdma_write_if1.address                             ),
  .netdma_write1_write                    ( netdma_write_if1.write                               ),
  .netdma_write1_read                     ( '0                                                   ),
  .netdma_write1_byteenable               ( 8'hff                                                ),
  .netdma_write1_debugaccess              ( '0                                                   ),
                           
  .netdma_read1_waitrequest               ( netdma_read_if1.waitrequest                          ),
  .netdma_read1_readdata                  ( netdma_read_if1.readdata                             ),
  .netdma_read1_readdatavalid             ( netdma_read_if1.readdatavalid                        ),
  .netdma_read1_burstcount                ( 1'd1                                                 ),
  .netdma_read1_writedata                 ( '0                                                   ),
  .netdma_read1_address                   ( netdma_read_if1.address                              ),
  .netdma_read1_write                     ( '0                                                   ),
  .netdma_read1_read                      ( netdma_read_if1.read                                 ),
  .netdma_read1_byteenable                ( 8'hff                                                ),
  .netdma_read1_debugaccess               ( '0                                                   ),
                           
  .netdma_read0_waitrequest               ( netdma_read_if0.waitrequest                          ),
  .netdma_read0_readdata                  ( netdma_read_if0.readdata                             ),
  .netdma_read0_readdatavalid             ( netdma_read_if0.readdatavalid                        ),
  .netdma_read0_burstcount                ( 1'd1                                                 ),
  .netdma_read0_writedata                 ( '0                                                   ),
  .netdma_read0_address                   ( netdma_read_if0.address                              ),
  .netdma_read0_write                     ( '0                                                   ),
  .netdma_read0_read                      ( netdma_read_if0.read                                 ),
  .netdma_read0_byteenable                ( 8'hff                                                ),
  .netdma_read0_debugaccess               ( '0                                                   ),


  .netdma_csr0_waitrequest                ( netdma_cpu_if0.waitrequest                           ),
  .netdma_csr0_readdata                   ( netdma_cpu_if0.readdata                              ),
  .netdma_csr0_readdatavalid              ( netdma_cpu_if0.readdatavalid                         ),
  .netdma_csr0_burstcount                 (                                                      ),
  .netdma_csr0_writedata                  ( netdma_cpu_if0.writedata                             ),
  .netdma_csr0_address                    ( netdma_cpu_if0.address                               ),
  .netdma_csr0_write                      ( netdma_cpu_if0.write                                 ),
  .netdma_csr0_read                       ( netdma_cpu_if0.read                                  ),
  .netdma_csr0_byteenable                 (                                                      ),
  .netdma_csr0_debugaccess                (                                                      ),
   
  .netdma_csr1_waitrequest                ( netdma_cpu_if1.waitrequest                           ),
  .netdma_csr1_readdata                   ( netdma_cpu_if1.readdata                              ),
  .netdma_csr1_readdatavalid              ( netdma_cpu_if1.readdatavalid                         ),
  .netdma_csr1_burstcount                 (                                                      ),
  .netdma_csr1_writedata                  ( netdma_cpu_if1.writedata                             ),
  .netdma_csr1_address                    ( netdma_cpu_if1.address                               ),
  .netdma_csr1_write                      ( netdma_cpu_if1.write                                 ),
  .netdma_csr1_read                       ( netdma_cpu_if1.read                                  ),
  .netdma_csr1_byteenable                 (                                                      ),
  .netdma_csr1_debugaccess                (                                                      ),


  .csr_waitrequest                        ( etnsoc_if.soc.csr_waitrequest                        ),
  .csr_readdata                           ( etnsoc_if.soc.csr_readdata                           ),
  .csr_readdatavalid                      ( etnsoc_if.soc.csr_readdatavalid                      ),
  .csr_burstcount                         ( etnsoc_if.soc.csr_burstcount                         ),
  .csr_writedata                          ( etnsoc_if.soc.csr_writedata                          ),
  .csr_address                            ( etnsoc_if.soc.csr_address                            ),
  .csr_write                              ( etnsoc_if.soc.csr_write                              ),
  .csr_read                               ( etnsoc_if.soc.csr_read                               ),
  .csr_byteenable                         ( etnsoc_if.soc.csr_byteenable                         ),
  .csr_debugaccess                        ( etnsoc_if.soc.csr_debugaccess                        ),

  .memory_mem_a                           ( memory_mem_a                                         ),
  .memory_mem_ba                          ( memory_mem_ba                                        ),
  .memory_mem_ck                          ( memory_mem_ck                                        ),
  .memory_mem_ck_n                        ( memory_mem_ck_n                                      ),
  .memory_mem_cke                         ( memory_mem_cke                                       ),
  .memory_mem_cs_n                        ( memory_mem_cs_n                                      ),
  .memory_mem_ras_n                       ( memory_mem_ras_n                                     ),
  .memory_mem_cas_n                       ( memory_mem_cas_n                                     ),
  .memory_mem_we_n                        ( memory_mem_we_n                                      ),
  .memory_mem_reset_n                     ( memory_mem_reset_n                                   ),
  .memory_mem_dq                          ( memory_mem_dq                                        ),
  .memory_mem_dqs                         ( memory_mem_dqs                                       ),
  .memory_mem_dqs_n                       ( memory_mem_dqs_n                                     ),
  .memory_mem_odt                         ( memory_mem_odt                                       ),
  .memory_mem_dm                          ( memory_mem_dm                                        ),
  .memory_oct_rzqin                       ( memory_oct_rzqin                                     ),
    
  .hps_io_hps_io_emac1_inst_TX_CLK        ( hps_io_hps_io_emac1_inst_TX_CLK),
  .hps_io_hps_io_emac1_inst_TXD0          ( hps_io_hps_io_emac1_inst_TXD0  ),
  .hps_io_hps_io_emac1_inst_TXD1          ( hps_io_hps_io_emac1_inst_TXD1  ),
  .hps_io_hps_io_emac1_inst_TXD2          ( hps_io_hps_io_emac1_inst_TXD2  ),
  .hps_io_hps_io_emac1_inst_TXD3          ( hps_io_hps_io_emac1_inst_TXD3  ),
  .hps_io_hps_io_emac1_inst_RXD0          ( hps_io_hps_io_emac1_inst_RXD0  ),
  .hps_io_hps_io_emac1_inst_MDIO          ( hps_io_hps_io_emac1_inst_MDIO  ),
  .hps_io_hps_io_emac1_inst_MDC           ( hps_io_hps_io_emac1_inst_MDC   ),
  .hps_io_hps_io_emac1_inst_RX_CTL        ( hps_io_hps_io_emac1_inst_RX_CTL),
  .hps_io_hps_io_emac1_inst_TX_CTL        ( hps_io_hps_io_emac1_inst_TX_CTL),
  .hps_io_hps_io_emac1_inst_RX_CLK        ( hps_io_hps_io_emac1_inst_RX_CLK),
  .hps_io_hps_io_emac1_inst_RXD1          ( hps_io_hps_io_emac1_inst_RXD1  ),
  .hps_io_hps_io_emac1_inst_RXD2          ( hps_io_hps_io_emac1_inst_RXD2  ),
  .hps_io_hps_io_emac1_inst_RXD3          ( hps_io_hps_io_emac1_inst_RXD3  ),
  .hps_io_hps_io_qspi_inst_IO0            ( hps_io_hps_io_qspi_inst_IO0    ),
  .hps_io_hps_io_qspi_inst_IO1            ( hps_io_hps_io_qspi_inst_IO1    ),
  .hps_io_hps_io_qspi_inst_IO2            ( hps_io_hps_io_qspi_inst_IO2    ),
  .hps_io_hps_io_qspi_inst_IO3            ( hps_io_hps_io_qspi_inst_IO3    ),
  .hps_io_hps_io_qspi_inst_SS0            ( hps_io_hps_io_qspi_inst_SS0    ),
  .hps_io_hps_io_qspi_inst_CLK            ( hps_io_hps_io_qspi_inst_CLK    ),
  .hps_io_hps_io_sdio_inst_CMD            ( hps_io_hps_io_sdio_inst_CMD    ),
  .hps_io_hps_io_sdio_inst_D0             ( hps_io_hps_io_sdio_inst_D0     ),
  .hps_io_hps_io_sdio_inst_D1             ( hps_io_hps_io_sdio_inst_D1     ),
  .hps_io_hps_io_sdio_inst_CLK            ( hps_io_hps_io_sdio_inst_CLK    ),
  .hps_io_hps_io_sdio_inst_D2             ( hps_io_hps_io_sdio_inst_D2     ),
  .hps_io_hps_io_sdio_inst_D3             ( hps_io_hps_io_sdio_inst_D3     ),
  .hps_io_hps_io_usb1_inst_D0             ( hps_io_hps_io_usb1_inst_D0     ),
  .hps_io_hps_io_usb1_inst_D1             ( hps_io_hps_io_usb1_inst_D1     ),
  .hps_io_hps_io_usb1_inst_D2             ( hps_io_hps_io_usb1_inst_D2     ),
  .hps_io_hps_io_usb1_inst_D3             ( hps_io_hps_io_usb1_inst_D3     ),
  .hps_io_hps_io_usb1_inst_D4             ( hps_io_hps_io_usb1_inst_D4     ),
  .hps_io_hps_io_usb1_inst_D5             ( hps_io_hps_io_usb1_inst_D5     ),
  .hps_io_hps_io_usb1_inst_D6             ( hps_io_hps_io_usb1_inst_D6     ),
  .hps_io_hps_io_usb1_inst_D7             ( hps_io_hps_io_usb1_inst_D7     ),
  .hps_io_hps_io_usb1_inst_CLK            ( hps_io_hps_io_usb1_inst_CLK    ),
  .hps_io_hps_io_usb1_inst_STP            ( hps_io_hps_io_usb1_inst_STP    ),
  .hps_io_hps_io_usb1_inst_DIR            ( hps_io_hps_io_usb1_inst_DIR    ),
  .hps_io_hps_io_usb1_inst_NXT            ( hps_io_hps_io_usb1_inst_NXT    ),
  .hps_io_hps_io_uart0_inst_RX            ( hps_io_hps_io_uart0_inst_RX    ),
  .hps_io_hps_io_uart0_inst_TX            ( hps_io_hps_io_uart0_inst_TX    ),
  .hps_io_hps_io_i2c0_inst_SDA            ( hps_io_hps_io_i2c0_inst_SDA    ),
  .hps_io_hps_io_i2c0_inst_SCL            ( hps_io_hps_io_i2c0_inst_SCL    ),
  .hps_io_hps_io_gpio_inst_GPIO09         ( hps_io_hps_io_gpio_inst_GPIO09 ),
  .hps_io_hps_io_gpio_inst_GPIO37         ( hps_io_hps_io_gpio_inst_GPIO37 ),
  .hps_io_hps_io_gpio_inst_GPIO44         ( hps_io_hps_io_gpio_inst_GPIO44 ),
  .hps_io_hps_io_gpio_inst_GPIO48         ( hps_io_hps_io_gpio_inst_GPIO48 ),
  .hps_io_hps_io_gpio_inst_GPIO52         ( hps_io_hps_io_gpio_inst_GPIO52 ),
  .hps_io_hps_io_gpio_inst_GPIO65         ( hps_io_hps_io_gpio_inst_GPIO65 ),
  .hps_io_hps_io_gpio_inst_LOANIO58       ( hps_io_hps_io_gpio_inst_LOANIO58 ),

  .hps_loan_io_in                         ( hps_loan_io_in                   ),
  .hps_loan_io_out                        ( hps_loan_io_out                  ),
  .hps_loan_io_oe                         ( hps_loan_io_oe                   )
);

assign  irq0_irq[0]    = netdma_cpu_if0.tx_irq;
assign  irq0_irq[1]    = netdma_cpu_if0.rx_irq;
assign  irq0_irq[2]    = netdma_cpu_if1.tx_irq;
assign  irq0_irq[3]    = netdma_cpu_if1.rx_irq;
assign  irq0_irq[31:4] = 'd0;


pll_gbe pll_gbe(
  .refclk               ( clk_25m_i                 ),
  .rst                  ( 1'b0                      ),
  .outclk_0             ( clk_125m                  ),
  .outclk_1             ( clk_62_5m                 ),
  .outclk_2             ( clk_25m                   ),
  .locked               (                           ),
  .reconfig_to_pll      ( /*pgr_reconfig_to_pll*/   ),
  .reconfig_from_pll    ( /*pgr_reconfig_from_pll*/ )
);

m88e1512_adapter #(
  .PORT_SWAP                              ( 0                 )
) m88e1512_adapter (

  .trg_clk125m_i                          ( trg_clk125m_i     ),

  .trg_rx_clk_i                           ( trg_rx_clk_i      ),
  .trg_rxd_i                              ( trg_rxd_i         ),
  .trg_rx_ctrl_i                          ( trg_rx_ctrl_i     ),

  .trg_tx_clk_o                           ( trg_tx_clk_o      ),
  .trg_txd_o                              ( trg_txd_o         ),
  .trg_tx_ctrl_o                          ( trg_tx_ctrl_o     ),

  .trg_mdc_o                              ( trg_mdc_o         ),
  .trg_mdio_io                            ( trg_mdio_io       ),

  .trg_nreset_o                           ( trg_nreset_o      ),

  .trg_ptpclk_o                           ( trg_ptpclk_o      ),
  .trg_ptp_int                            ( trg_ptp_int       ),
  .trg_ptp_io                             ( trg_ptp_io        ),

  .trg_if                                 ( trg_if            )
);

etn_main main (

  .clk_62_5m_i                            ( clk_62_5m         ),
  .clk_125m_i                             ( clk_125m          ),

  .etnsoc_if                              ( etnsoc_if         ),

  .netdma_cpu_if0                         ( netdma_cpu_if0    ),
  .netdma_cpu_if1                         ( netdma_cpu_if1    ),
  .netdma_write_if0                       ( netdma_write_if0  ),
  .netdma_write_if1                       ( netdma_write_if1  ),
  .netdma_read_if0                        ( netdma_read_if0   ),
  .netdma_read_if1                        ( netdma_read_if1   ),

  .trg_if                                 ( trg_if            )
);




endmodule
