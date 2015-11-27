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

/*
  Модуль преобразует avalon-mm в "наш" интерфейс
  управления контрольными-статусными регистрами.

  Код взят из модуля soc, куда он был добавлен ручками
  после того как весь интерконнект был сгенерирован
  с использованием QSYS.
*/

module avalon_mm_to_csr_if
#( 
  parameter AMM_DATA_W  = 32,
  parameter AMM_BE_W    = AMM_DATA_W >> 3,
  parameter REGS_DATA_W = 16,
  parameter REGS_BE_W   = REGS_DATA_W >> 3,
  parameter REGS_ADDR_W = 14
)
(
  input                    clk_i,
  input                    rst_i,
  
  // our regs interface
  csr_if.master            main_reg_csr_if,
  
  // avalon-mm stuff
  output                   avalon_mm_master_waitrequest,     
  output [AMM_DATA_W-1:0]  avalon_mm_master_readdata,        
  output                   avalon_mm_master_readdatavalid,   

  input  [0:0]             avalon_mm_master_burstcount,      
  input  [AMM_DATA_W-1:0]  avalon_mm_master_writedata,       
  input  [REGS_ADDR_W-1:0] avalon_mm_master_address,         
  input                    avalon_mm_master_write,           
  input                    avalon_mm_master_read,            
  input  [AMM_BE_W-1:0]    avalon_mm_master_byteenable,      
  input                    avalon_mm_master_debugaccess 
  
);

localparam H2F_REGS_W_RATIO  = AMM_DATA_W/REGS_DATA_W;

// 1024 regs -- is it 10 bit, but address is in words.
// Every word is two bytes, so bytes address is 11 bit.
// Master (wide) address always byte address.
// TODO:
//   Test WIDTH
localparam H2F_ADDR_W  = REGS_ADDR_W;

logic                        regs_write_w;
logic                        regs_read_w;
logic [REGS_ADDR_W-1:0]      regs_addr_w;
logic [REGS_DATA_W-1:0]      regs_wdata_w;
logic [REGS_BE_W-1:0]        regs_be_w;

logic [REGS_DATA_W-1:0]      regs_rdata_w;
logic                        regs_dv_w;
logic                        regs_wait_req_w;
       
avalon_width_adapter avalon_width_adapter_regs(
  .clk_i                                    ( clk_i                                      ),
  .rst_i                                    ( rst_i                                      ),

    // Wide IF
  .wide_writedata_i                         ( avalon_mm_master_writedata                 ),
  .wide_byteenable_i                        ( avalon_mm_master_byteenable                ),
  .wide_write_i                             ( avalon_mm_master_write                     ),
  .wide_read_i                              ( avalon_mm_master_read                      ),
  .wide_address_i                           ( avalon_mm_master_address                   ),

  .wide_readdata_o                          ( avalon_mm_master_readdata                  ),
  .wide_waitrequest_o                       ( avalon_mm_master_waitrequest               ),
  .wide_datavalid_o                         ( avalon_mm_master_readdatavalid             ),


  // Narrow IF
  .narrow_writedata_o                       ( regs_wdata_w                               ),
  .narrow_byteenable_o                      ( regs_be_w                                  ),
  .narrow_write_o                           ( regs_write_w                               ),
  .narrow_read_o                            ( regs_read_w                                ),
  .narrow_address_o                         ( regs_addr_w                                ),

  .narrow_readdata_i                        ( regs_rdata_w                               ),
  .narrow_datavalid_i                       ( regs_dv_w                                  ),
  .narrow_waitrequest_i                     ( regs_wait_req_w                            )
);

// We count registers in items.
defparam avalon_width_adapter_regs.SLAVE_ADDR_IS_BYTE = 0;
defparam avalon_width_adapter_regs.WIDTH_RATIO        = H2F_REGS_W_RATIO;
defparam avalon_width_adapter_regs.NARROW_IF_BE_W     = REGS_BE_W;
defparam avalon_width_adapter_regs.WIDE_IF_ADDR_W     = H2F_ADDR_W;


logic [1:0] csr_waitreq_cnt = 0;

always_comb
  regs_dv_w = ( csr_waitreq_cnt == 2'd2 );

always_comb
  regs_wait_req_w = regs_read_w && ( csr_waitreq_cnt != 2'd2 );

always_ff @( posedge clk_i )
  if( regs_wait_req_w == 0 )
    csr_waitreq_cnt <= '0;
  else
    csr_waitreq_cnt <= csr_waitreq_cnt + 1'b1;


always_ff @( posedge clk_i )
  begin
    main_reg_csr_if.addr    <= regs_addr_w;
    main_reg_csr_if.be      <= regs_be_w;
    main_reg_csr_if.wr_data <= regs_wdata_w;
    main_reg_csr_if.wr_en   <= regs_write_w;
  end


always_ff @( posedge clk_i )
  begin
    regs_rdata_w <= main_reg_csr_if.rd_data;
  end

endmodule
