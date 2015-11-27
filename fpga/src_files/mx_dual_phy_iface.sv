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
  Модуль содержит приемники и передатчики для 10G/1G интерфейсов,
  и они переводят "выцепляют" пакет из интерфейса и передают его дальше.

  Здесь происходит мультиплексирование между интерфейсами: 
  работать на прием/передачу может только один из них.

*/

module mx_dual_phy_iface(
  
  input                              rst_i,

  // 10G tx interface
  input                              xgmii_clk_i,

  input  [63:0]                      xgmii_rxd_i,
  input  [7:0]                       xgmii_rxc_i,
  
  output [63:0]                      xgmii_txd_o,
  output [7:0]                       xgmii_txc_o,
  
  gmii_phy_if.phy                    gmii_if,

  // to rx_engine
  rx_engine_if.fetcher               pkt_rx_o,

  // to tx_engine
  eth_pkt_if.i                       pkt_tx_i,
  output  logic                      pkt_tx_full_o

);
parameter  XGE_RX_EN = 1;
parameter  XGE_TX_EN = 1;
parameter  GBE_RX_EN = 1;
parameter  GBE_TX_EN = 1;

localparam XGE = 0;
localparam GBE = 1;

rx_engine_if pkt_rx[1:0]( );

logic  [1:0]                      rxdfifo_wen_w;  

// выбор направлений: 
// 0 - 10G
// 1 - 1G
logic                             rx_iface_sel;
logic                             tx_iface_sel;

logic                             rx_iface_sel_d1;
logic                             rx_iface_sel_d2;

// текущее "залоченное" направление 
logic                             rx_iface_sel_reg;

logic                             tx_iface_sel_d1;
logic                             tx_iface_sel_d2;
logic                             tx_iface_sel_reg;

eth_pkt_if #( .IF_TYPE( "10G" ) ) pkt_tx[1:0]( xgmii_clk_i );
eth_pkt_if #( .IF_TYPE( "10G" ) ) pkt_tx_d[0:0]( xgmii_clk_i );

// выбор физического интерфейса для передачи

// старший бит в скорости отвечает за выбор порта
// если там 0, то 10G выбрано, если 1 - то 10G
// младшие три бита показывают скорость 1G:
// 001 - 10M
// 010 - 100M
// 100 - 1000M

// NOTE: в MX у нас может быть, что входной 10G порт
// а выходной - 1G. Я думаю, для корректной работы 
// настройка должна быть такая:
// RX: 0100
// TX: 1100

// То есть желательно, что бы скорость гигабита на RX
// и TX была одинаковая, даже если один из портов 10G.
// но может это лишняя мера предосторожности.
assign rx_iface_sel = gmii_if.rx_speed[3];
assign tx_iface_sel = gmii_if.tx_speed[3];

always_ff @( posedge xgmii_clk_i or posedge rst_i )
  if( rst_i )
    begin
      rx_iface_sel_d1 <= '0;
      rx_iface_sel_d2 <= '0;
    end
  else
    begin
      rx_iface_sel_d1 <= rx_iface_sel;
      rx_iface_sel_d2 <= rx_iface_sel_d1;
    end


always_ff @( posedge xgmii_clk_i or posedge rst_i )
  if( rst_i )
    begin
      tx_iface_sel_d1 <= '0;
      tx_iface_sel_d2 <= '0;
    end
  else
    begin
      tx_iface_sel_d1 <= tx_iface_sel;
      tx_iface_sel_d2 <= tx_iface_sel_d1;
    end

generate
  if( XGE_RX_EN )
    begin : rxe
      rx_pkt_fetcher rx_pkt_fetcher(
        .clk_xgmii_rx_i                             ( xgmii_clk_i                 ),
        .reset_xgmii_rx_i                           ( rst_i                       ),

        .xgmii_rxd_i                                ( xgmii_rxd_i                 ),
        .xgmii_rxc_i                                ( xgmii_rxc_i                 ),
          
        .rxdfifo_wfull_i                            ( pkt_rx[XGE].fetcher.wr_full ),
        .rxdfifo_wdata_o                            ( pkt_rx[XGE].fetcher.data    ),
        .rxdfifo_wstatus_o                          ( pkt_rx[XGE].fetcher.status  ),
        .rxdfifo_werror_o                           ( pkt_rx[XGE].fetcher.error   ),
        .rxdfifo_pktlen_o                           ( pkt_rx[XGE].fetcher.pkt_len ),
        .rxdfifo_wen_o                              ( pkt_rx[XGE].fetcher.en      ),
          
        .local_fault_msg_det_o                      (   ),
        .remote_fault_msg_det_o                     (   )
      );
    end
  else
    begin
        assign pkt_rx[XGE].fetcher.data    = '0;   
        assign pkt_rx[XGE].fetcher.status  = '0;  
        assign pkt_rx[XGE].fetcher.error   = '0;  
        assign pkt_rx[XGE].fetcher.pkt_len = '0;  
        assign pkt_rx[XGE].fetcher.en      = '0;  
    end
endgenerate

generate
  if( ( XGE_RX_EN == 1 ) && ( GBE_RX_EN == 1 ) )
    begin
      // если есть и 10G и 1G то оставляем регистр для защелкивания направления
      always_ff @( posedge xgmii_clk_i or posedge rst_i )
        if( rst_i )
          rx_iface_sel_reg <= 1'b0;
        else
          // если в обоих не wen, то переключаем 
          if( ( rx_iface_sel_reg != rx_iface_sel_d2 ) && ( !( |rxdfifo_wen_w ) ) )
            rx_iface_sel_reg <= rx_iface_sel_d2;
    end
  else
    if( XGE_RX_EN == 1 )
      begin
        // если только 10G, то сразу присваиваем
        assign rx_iface_sel_reg = XGE;
      end
    else
      begin
        // аналогично для 1G 
        assign rx_iface_sel_reg = GBE;
      end
endgenerate



assign rxdfifo_wen_w[XGE] = pkt_rx[XGE].en;
assign rxdfifo_wen_w[GBE] = pkt_rx[GBE].en;

always_comb
  begin
    // я знаю что это пиздец, но моделсим не дает
    // выбирать из массива интерфейсов "переменной" ( типа pkt_rx[ rx_iface_sel_reg ] ).
    // пришлось делать такой хак
    if( rx_iface_sel_reg )
      begin
        pkt_rx_o.data       = pkt_rx[GBE].data;      
        pkt_rx_o.status     = pkt_rx[GBE].status;    
        pkt_rx_o.error      = pkt_rx[GBE].error;     
        pkt_rx_o.pkt_len    = pkt_rx[GBE].pkt_len;   
        pkt_rx_o.en         = pkt_rx[GBE].en;       
      end
   else
     begin
        pkt_rx_o.data       = pkt_rx[XGE].data;      
        pkt_rx_o.status     = pkt_rx[XGE].status;    
        pkt_rx_o.error      = pkt_rx[XGE].error;     
        pkt_rx_o.pkt_len    = pkt_rx[XGE].pkt_len;   
        pkt_rx_o.en         = pkt_rx[XGE].en;       
     end
  end

assign    pkt_rx[XGE].wr_full  = pkt_rx_o.wr_full;  
assign    pkt_rx[GBE].wr_full  = pkt_rx_o.wr_full;  

logic [1:0] port_pkt_tx_fifo_full;

conv_1G_top #( 
  .RX_EN                                 ( GBE_RX_EN                     ),
  .TX_EN                                 ( GBE_TX_EN                     ),
  .REDUCED_TX_FIFO                       ( 1                             )
) conv_1G_top (
  .Reset                                  ( rst_i                        ),
  // xgmii clk у нас выступает в роли системного
  .Clk_user                               ( xgmii_clk_i                  ),
                  
  // Phy interface         
  .Tx_clk                                 ( gmii_if.tx_clk               ),
  .Tx_er                                  ( gmii_if.tx_err               ),
  .Tx_en                                  ( gmii_if.tx_en                ),
  .Txd                                    ( gmii_if.tx_d                 ),
  
  .Rx_clk                                 ( gmii_if.rx_clk               ),
  .Rx_er                                  ( gmii_if.rx_err               ),
  .Rx_dv                                  ( gmii_if.rx_dv                ),
  .Rxd                                    ( gmii_if.rx_d                 ),
  //.Crs                                    ( gmii_if.crs                  ),

  .RxSpeed                                ( gmii_if.rx_speed[2:0]        ),
  .TxSpeed                                ( gmii_if.tx_speed[2:0]        ),

  //to traf_engine rx
  .tr_en_fifo_full_i                      ( pkt_rx[GBE].fetcher.wr_full  ),
  .pkt_conv_rx_data_o                     ( pkt_rx[GBE].fetcher.data     ),
  .pkt_conv_rx_status_o                   ( pkt_rx[GBE].fetcher.status   ),
  .pkt_conv_rx_error_o                    ( pkt_rx[GBE].fetcher.error    ),
  .pkt_conv_rx_len_o                      ( pkt_rx[GBE].fetcher.pkt_len  ),
  .pkt_conv_rx_val_o                      ( pkt_rx[GBE].fetcher.en       ),

  // from engine tx
  .pkt_conv_tx_data_i                     ( pkt_tx[GBE].data             ),
  .pkt_conv_tx_mod_i                      ( pkt_tx[GBE].mod              ),
  .pkt_conv_tx_sop_i                      ( pkt_tx[GBE].sop              ),
  .pkt_conv_tx_eop_i                      ( pkt_tx[GBE].eop              ),
  .pkt_conv_tx_val_i                      ( pkt_tx[GBE].val              ),
  .conv_tx_fifo_full_o                    ( port_pkt_tx_fifo_full[GBE]   )
);

assign pkt_tx[GBE].ready = ~port_pkt_tx_fifo_full[GBE]; 

generate
  if( XGE_TX_EN )
    begin : txe
      tx_engine port_tx_engine(
        .clk_156m25_i                           ( xgmii_clk_i                    ), 
        .clk_xgmii_tx_i                         ( xgmii_clk_i                    ),
        .reset_156m25_i                         ( rst_i                          ),
        .reset_xgmii_tx_i                       ( rst_i                          ),

        .pkt_tx_data_i                          ( pkt_tx[XGE].data               ),
        .pkt_tx_eop_i                           ( pkt_tx[XGE].eop                ),
        .pkt_tx_mod_i                           ( pkt_tx[XGE].mod                ),
        .pkt_tx_sop_i                           ( pkt_tx[XGE].sop                ),
        .pkt_tx_val_i                           ( pkt_tx[XGE].val                ),
          
        .pkt_patt_en_i                          ( 1'b0                           ),
        .pkt_patt_first_byte_i                  ( 32'b0                          ),
          
        .pkt_tx_full_o                          ( port_pkt_tx_fifo_full[XGE]     ),

        .xgmii_txc_o                            ( xgmii_txc_o                    ),
        .xgmii_txd_o                            ( xgmii_txd_o                    ),

        .status_local_fault_ctx                 ( 1'b0                           ),
        .status_remote_fault_ctx                ( 1'b0                           ),

        .crc_err_count_i                        ( 16'b0                          ),
        .crc_err_period_count_i                 ( 32'b0                          ),
        .crc_err_counters_load_i                ( 1'b0                           ),

        .tx_min_size_sel_i                      ( 1'b0                           )
      );
    end
  else
    begin
      assign port_pkt_tx_fifo_full[XGE] = 1'b0;
      assign xgmii_txc_o                = 8'hFF;
      assign xgmii_txd_o                = 64'h07070707_07070707; 
    end
endgenerate

always_ff @( posedge xgmii_clk_i or posedge rst_i )
  if( rst_i )
    tx_iface_sel_reg <= '0;
  else
    if( pkt_tx_i.val && pkt_tx_i.sop )
      tx_iface_sel_reg <= tx_iface_sel_d2;


//FIXME    
always_comb
  begin
    if( tx_iface_sel_d2 != tx_iface_sel_reg )
      pkt_tx_full_o = 1'b0;
    else
      pkt_tx_full_o = port_pkt_tx_fifo_full[ tx_iface_sel_reg ];
  end

//FIXME:

eth_pkt_if_delay
#
( 
  .DELAY                                  ( 1                 )
) pkt_tx_delay
(
  .rst_i                                  ( rst_i             ),

  .pkt_i                                  ( pkt_tx_i          ),

  .pkt_o                                  ( pkt_tx[GBE]       )

);

/*
logic [1:0] tx_dmx_dir;

assign tx_dmx_dir[XGE] = ~tx_iface_sel_reg;
assign tx_dmx_dir[GBE] =  tx_iface_sel_reg;



cge_switch
#
( 
  .RX_DIR                                 ( 1                                   ),
  .TX_DIR                                 ( 2                                   ),
  .IF_TYPE                                ( "10G"                               )
) tx_dmx
(
  .rx_direction_num_i                     ( 1'd0                                ),
  .tx_direction_mask_i                    ( tx_dmx_dir                          ),

  .pkt_i                                  ( pkt_tx_d                            ),
 
  .pkt_o                                  ( pkt_tx                              )

);
*/

endmodule
