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
  Модуль преобразования csr_if в интерфейс идентификации прошивки FPGA
  и получения битовой маски разрешенных опций.

*/

`include "mx_fpga_id_regs.vh"

module mx_fpga_id_to_if
#(
   parameter D_WIDTH = 16,
   parameter A_WIDTH = 10
)
(
  
  csr_if.slave                   regfile_if,
  
  fpga_id_if.master              fpga_id_rom_if

);
localparam CR_CNT  = `MX_FPGA_ID_CR_CNT;
localparam SR_CNT  = `MX_FPGA_ID_SR_CNT;

logic [D_WIDTH-1:0] cregs_w [CR_CNT-1:0];
logic [D_WIDTH-1:0] sregs_w [SR_CNT-1:0];
logic [D_WIDTH-1:0] regfile_rd_data_w;

assign fpga_id_rom_if.rd_addr          =   cregs_w[`FPGA_ID_CR][ `FPGA_ID_CR_RD_ADDR_B7:
                                                                 `FPGA_ID_CR_RD_ADDR_B0 ];

/*
  Для того, что бы всегда в начале CSR пространства была идентификация прошивки и
  чтение не зависило от количества контрольных регистров у этой фичи
  мы применяем следующий хак:
    0 и 1 регистр на самом деле статусные, т.к. они только на чтение.
    Записать туда можно, но прочитается не то, что было записано :) 

  При чтении мы просто подменяем результат чтения, если это 0 или 1 регистр.
*/

always_comb
  begin
    case( regfile_if.addr )
      `FPGA_ID_RD_DATA_W0_CR:
        begin
          regfile_if.rd_data = fpga_id_rom_if.rd_data[15:0];
        end
      `FPGA_ID_RD_DATA_W1_CR:
        begin
          regfile_if.rd_data = fpga_id_rom_if.rd_data[31:16];
        end
      default:
        begin
          regfile_if.rd_data = regfile_rd_data_w;
        end
    endcase
  end


regfile_with_be #( 
  .CTRL_CNT                               ( CR_CNT               ), 
  .STAT_CNT                               ( SR_CNT               ), 
  .ADDR_W                                 ( A_WIDTH              ), 
  .DATA_W                                 ( D_WIDTH              ), 
  .SEL_SR_BY_MSB                             ( 0                    )
) fpga_id_regfile (
  .clk_i                                  ( regfile_if.clk       ),
  .rst_i                                  ( 1'b0                 ),

  .data_i                                 ( regfile_if.wr_data   ),
  .wren_i                                 ( regfile_if.wr_en     ),
  .addr_i                                 ( regfile_if.addr      ),
  .be_i                                   ( regfile_if.be        ),
  .sreg_i                                 ( sregs_w              ),
  .data_o                                 ( regfile_rd_data_w    ),
  .creg_o                                 ( cregs_w              )
); 


endmodule
