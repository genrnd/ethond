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
  Интерфейс для настройки сетевого стека.
*/

interface nic_ctrl_if( input clk_i );
  
  logic [47:0] host_mac;

  // vlan, используемый для инкапсуляции пакетов
  // для пересылки на CPU
  logic [11:0] encaps_vlan;
  
  // альтернативный (второй mac адрес девайса)
  logic [47:0] alt_host_mac;
  
  // флаг о том, что для принятия решения о том, что
  // это "наш" пакет, надо еще смотреть на альтернативный mac-адрес
  logic        also_use_alt_host_mac;

  // включение промиска:
  // сетевой стек не будет смотреть на MAC'адрес, и все пакеты
  // пойдут на CPU, кроме тестовых и плохих
  logic        promisc_mode;

  // Значение MTU, установленное для интерфейса
  logic [15:0] mtu;


modport csr(
  output host_mac,
         encaps_vlan,

         alt_host_mac,
         also_use_alt_host_mac,
         promisc_mode,
         mtu
);

modport app(

  input host_mac,
        encaps_vlan,
        alt_host_mac,
        also_use_alt_host_mac,
        promisc_mode,
        mtu
);

endinterface
