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

package xge_rx;

  typedef struct packed {
    logic broadcast;
    logic multicast;
    logic unicast;
    logic samemacs;
    logic crc_err;
    logic runt;
    logic oversize;
    logic ethertype_lb;

    logic [15:0] pkt_size;
    
    logic oam;
    logic telnet;
    logic signature;
    logic bert;
    logic ipv4; 
    logic et_discover;
    
    logic ptp;

    logic [31:0] pkt_rx_time;
    
    logic xcap;
    
    // пакет управляющего протокола twamp
    logic twamp_control;

    // пакет от sender'a -> на рефлектор
    logic twamp_sender;

    // пакет от рефлектора -> на анализатор
    logic twamp_reflector;

    // номер потока twamp ( 15-0 )
    logic [3:0] twamp_test_flow_num;     

    // our mac
    logic       usercast;
    
    logic       nic_encaps;

    logic       icmp; 
    logic       dhcp; 
    logic       dns;  
    logic       arp;  
        
    logic [1:0] vlan_cnt;
    logic [1:0] mpls_cnt;
    
    logic       ssh;
    logic       tcp;
    logic       udp;
  } pkt_rx_info_t;

// дефайны для направлений в traf_engine
parameter RX_DIR_DROP         = 0;
parameter RX_DIR_CPU          = 1;
parameter RX_DIR_CNT          = 2;

endpackage
