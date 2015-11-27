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
   Модуль просто объединяет модуль mdio и быструю прогрузку,
   что бы меньше в топе висело.
*/

module mdio_wrapper
#( 
  parameter ENABLE_FIRMWARE_LOAD = 1 
)
(
  // клок для mdio: для MX это 25 МГц
  input           clk_i,
  
  // интерфейс с настройками - просто пробрасываем csr
  mdio_if.slave   mdio_if,
  
  // MDIO data line
  inout           mdio_io,     

  // MDC clock line   
  output          mdc_o         

);

logic          md_i_w;          // input serial data for MDIO
logic          md_o_w;          // output serial data from MDIO
logic          mdoen_w;         // out en for tri-state buffers
logic          mdio_run_w;      // строб запуска mdio контроллера
logic          xmdio_fw_run_w;  // строб для записи в fw_fifo 

logic   [1:0]  xmdio_cop;       // cop to mdio ctrl
logic          xmdio_run;       // run_strob to mdio ctrl 
logic   [15:0] xmdio_data;      // data to mdio ctrl

/*
   Для трансиверов vitesse приходится подгружать специальный
   микрокод для sfp+ модулей, которые limiting amplifier. 
   Это делается через mdio. Для ускорения записи был написан
   модуль которые эти данные у себя складывает в fifo,
   и сам выставляет нужный cop и address, куда писать.
   Когда происходит загрузка прошивки, необходимо что бы никто
   больше не пользовался mdio.
*/

logic   [1:0]  fw_mdio_cop;     //cop from fw load
logic          fw_mdio_run;     //run_strob from fw load
logic   [15:0] fw_mdio_data;    //data from fw load

logic          fw_load;         //now is loading firmware in vitesse

assign         fw_load = ( ENABLE_FIRMWARE_LOAD == 1 ) && mdio_if.fw_loading;

// Если загружаем прошивку, то используем выход от firmware load,
// в противном - от контрольных регистров ("нормальная ситуация")
always_comb
  begin
    if( fw_load )
      begin
        xmdio_cop  = fw_mdio_cop;
        xmdio_run  = fw_mdio_run;
        xmdio_data = fw_mdio_data;
      end
    else
      begin
        xmdio_cop  = mdio_if.cop;
        xmdio_run  = mdio_run_w;
        xmdio_data = mdio_if.wr_data;
      end
  end


sedge_sel_sv mdio_run_edge_sel(
  .Clk                          ( clk_i                         ),
  .ain                          ( mdio_if.run                   ),
  .edg                          ( mdio_run_w                    )
);

sedge_sel_sv mdio_fw_run_edge_sel(
  .Clk                          ( clk_i                         ),
  .ain                          ( mdio_if.fw_run                ),
  .edg                          ( xmdio_fw_run_w                )
);

mdio mdio(
  .clk_i                        (  clk_i                        ),
  .rst_i                        (  mdio_if.rst                  ),
  
  .run_i                        (  xmdio_run                    ),
  .cop_i                        (  xmdio_cop                    ),
  
  .data_i                       (  xmdio_data                   ),
  
  .phyaddr_i                    (  mdio_if.phy_addr             ),
  .devaddr_i                    (  mdio_if.dev_addr             ),
  
  .divider_i                    (  mdio_if.divider              ),
  
  .md_i                         (  md_i_w                       ),
  .mdc_o                        (  mdc_o                        ),
  .md_o                         (  md_o_w                       ),
  .mdoen_o                      (  mdoen_w                      ),
  .busy_o                       (  mdio_if.busy                 ),
  
  .data_val_o                   (  mdio_if.rd_data_val          ),
  .data_o                       (  mdio_if.rd_data              )
);
    
// making clause 22
defparam mdio.ST = 2'b01;

//Tri-state buffer for MDIO 
assign mdio_io = mdoen_w ? md_o_w : 1'bz;
assign md_i_w  = mdio_io;

generate
  begin
    if( ENABLE_FIRMWARE_LOAD )
      begin
        firmware_load firmware_load(
          .clk_i                        ( clk_i                         ),
          .rst_i                        ( mdio_if.fw_rst                ), 
          .en_i                         ( fw_load                       ),
          .fw_run_i                     ( xmdio_fw_run_w                ),

          .mdio_busy_i                  ( mdio_if.busy                  ),

          .fw_word0_i                   ( mdio_if.fw_wr_data_w0         ),
          .fw_word1_i                   ( mdio_if.fw_wr_data_w1         ),

          .fw_fifo_busy_o               ( mdio_if.fw_busy               ),
          .fw_mdio_cop_o                ( fw_mdio_cop                   ),
          .fw_mdio_run_o                ( fw_mdio_run                   ),
          .fw_mdio_data_o               ( fw_mdio_data                  )
        );
      end
    else
      begin
          // ставим busy, т.к. прошивкой нельзя воспользоваться
          // если её нет :)
          assign mdio_if.fw_busy = 1'b1; 
          assign fw_mdio_cop     = '0;         
          assign fw_mdio_run     = '0;         
          assign fw_mdio_data    = '0;     
      end
  end
endgenerate

endmodule
