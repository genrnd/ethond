/*
  CSR для управления сетевым стеком

*/

`define NIC_CTRL_VER 16'h0_0_0_1

/* CONTROL REGISTERS */

// значение host mac'a
`define HOST_MAC_W0_CR 0
`define HOST_MAC_W1_CR 1
`define HOST_MAC_W2_CR 2

// номер 
`define MGMT_VLAN_CR 3
        `define MGMT_VLAN_CR_VLAN_NUM_B0   0
        `define MGMT_VLAN_CR_VLAN_NUM_B11  11

// значение "альтернативного" host mac'a
`define ALT_HOST_MAC_W0_CR 4        
`define ALT_HOST_MAC_W1_CR 5 
`define ALT_HOST_MAC_W2_CR 6        

// настройка работы режима работы сетевого стека
`define NIC_MAIN_CR 7 
        `define NIC_MAIN_CR_MODE_B0 0
        `define NIC_MAIN_CR_MODE_B1 1

`define NIC_CTRL_CR_CNT    8

/* STATUS REGISTERS */

`define NIC_CTRL_VER_SR        0

`define NIC_CTRL_SR_CNT        1

/*

// ********** NIC CTRL **********

Управление интерфейсом чтения-записи пакетов для сетевого стека MCU ( arp, ping, etc ).
  
  Настройка host_mac:
    FPGA должно знать свой mac, что бы только пакеты с этим маком получателя уходили на CPU.  
    Настраивается в HOST_MAC_W2_CR/W0_CR: если наш MAC 00:21:CE:AA:BB:CC, то необходимо записать вот
      _W2_CR : 0xCCBB
      _W1_CR : 0xAACE
      _W0_CR : 0x2100

  Настройка номера управляющего VLAN'а:
    С CPU мы общаемся по выделенному VLAN'у. Нам его назнать, что бы
    пакеты с этим VLAN'ом распознавали как ОТ CPU и мы просто снимали
    хедер посылали обратно.

    Просто ставим значение этого VLAN'a в:
      MGMT_VLAN_CR_VLAN_NUM_B11/B0

  Настройка альтернативного HOST_MAC'a:
    Аналогична (порядок байт) обычному HOST_MAC, только используются регистры ALT_HOST_MAC.
    Он необходим, если на CPU (Linux) надо иметь как-бы 2 MAC-адреса 
    (связано с нюансами реализации сетевого стека в проекте ETN/ETU).
  
  Настройка режима работы сетевого стека MIC_MAIN_CR_MODE_B1/B0:
    0x0 - "обычная" работа - используется только HOST_MAC.
    0x1 - reserved - не надо использовать(!)
    0x2 - дополнительно настроен альтернативный MAC: считаем, что у пакета "наш" мак,
          если его MAC_DST равен HOST_MAC, либо ALT_HOST_MAC.
    0x3 - промиск режим: отключается проверка на MAC_DST: на сетевой будут уходить все пакеты,
          кроме тех, которые признаны "плохими" [битая CRC, etc] и "тестовыми".
          Подробнее, как обычно см. в traf_engine_rx_dir_resolver.
*/
