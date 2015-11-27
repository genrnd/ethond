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

module etnsoc2app(
  input         clk_i,
  etnsoc_if.app etnsoc_if,
  csr_if.master main_reg_csr_if
);

assign etnsoc_if.clk = clk_i;


avalon_mm_to_csr_if amm2csr(
  .clk_i                                  ( etnsoc_if.clk               ),
  .rst_i                                  ( etnsoc_if.rst               ),
    
    // our regs interface
  .main_reg_csr_if                        ( main_reg_csr_if             ),
    
    // avalon-mm stuff
  .avalon_mm_master_waitrequest           ( etnsoc_if.csr_waitrequest   ),
  .avalon_mm_master_readdata              ( etnsoc_if.csr_readdata      ),
  .avalon_mm_master_readdatavalid         ( etnsoc_if.csr_readdatavalid ),

  .avalon_mm_master_burstcount            ( etnsoc_if.csr_burstcount    ),
  .avalon_mm_master_writedata             ( etnsoc_if.csr_writedata     ),
  .avalon_mm_master_address               ( etnsoc_if.csr_address       ),
  .avalon_mm_master_write                 ( etnsoc_if.csr_write         ),
  .avalon_mm_master_read                  ( etnsoc_if.csr_read          ),
  .avalon_mm_master_byteenable            ( etnsoc_if.csr_byteenable    ),
  .avalon_mm_master_debugaccess           ( etnsoc_if.csr_debugaccess   )
  
);

endmodule
