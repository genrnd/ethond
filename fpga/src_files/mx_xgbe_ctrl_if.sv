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
  Интерфейс с сигналами управления и получения 
  статусной информации 1G/10G трансиверов.

  Так же сюда вошли сигналы, которые не особо входят в другие интерфейсы,
  а отдельного интерфейса бессмысленно выделять.
*/

interface mx_xgbe_ctrl_if
(

);

// ****** 10G *****
// выключение передачи в SFP
  logic       tx_disable;

// отсутствие модуля
  logic       mod_abs;

// отсутствие сигнала
  logic       rx_los;

// сломался передатчик SFP+
  logic       tx_fault;

// loss of optical power    
  logic       lopc;

  logic       xge_nreset;

// ****** 1G *****

  logic       gbe_nreset;
  logic       gbe_coma;

// ****** other *****
  logic       alrm_led;
  
  logic       rx_led;

  logic       test_led;
  
  // скорость по порту
  // 0000 - 10Gb/s [ XGE порт ], 
  // 1001 - 10Mb/s; 1010 - 100 Mb/s; 1100 - 1000 Mb/s [ GBE порт ]
  logic  [3:0] rx_port_speed;
  logic  [3:0] tx_port_speed;
  
  // асинхронный сброс main_engine
  logic  main_engine_arst;
  
  // сигнал только для tb, когда мы через регистры настройли
  // app_logic и можно запускать трафик
  logic  tb_gen_pkt_en;



modport slave(

  input  tx_disable,

  output mod_abs,
         rx_los,
         tx_fault,
         lopc,

  input xge_nreset,


  input gbe_nreset,
        gbe_coma,

  input alrm_led,
        rx_led,
        test_led,

        rx_port_speed,
        tx_port_speed,
        main_engine_arst,

        tb_gen_pkt_en

);


modport master(

  output tx_disable,

  input  mod_abs,
         rx_los,
         tx_fault,
         lopc,

  output xge_nreset,


  output gbe_nreset,
         gbe_coma,

  output alrm_led,
         rx_led,
         test_led,

         rx_port_speed,
         tx_port_speed,
         main_engine_arst,
         tb_gen_pkt_en

);


endinterface
