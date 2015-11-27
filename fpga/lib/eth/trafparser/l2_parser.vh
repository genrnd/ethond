`define MACD_POS       0
`define MACD_BITS_POS  47:0

`define MACS_POS_START 0
`define MACS_POS_END   1

`define MACS_BITS_POS_START 63:48
`define MACS_BITS_POS_END   31:0


//VLAN Section
`define VLANTPID0 16'h0081       //TPID по которым обнаруживаем VLAN
`define VLANTPID1 16'ha888       //байты поменяны местами

  //дефайны для первого vlan тега
`define VLAN0_POS 1              //в первом слове может находиться vlan0/ethertype

`define VLANTPID0_BITS_POS 47:32 //расположение битов с TPID vlan0 в слове
`define VLANID0_BITS_POS   63:48 //расположение битов с VLAN ID vlan0 в слове

//`define ETHTYPE0_BITS_POS  47:32 //расположение битов с ethertype при отсутствии vlan'ов

  //дефайны для второго vlan тега
`define VLAN1_POS 2              //во втором слове может находиться vlan1/ethertype
`define VLANTPID1_BITS_POS 15:0  //расположение битов с TPID vlan0 в слове
`define VLANID1_BITS_POS   31:16 //расположение битов с VLAN ID vlan0 в слове

//`define ETHTYPE1_BITS_POS  15:0  //расположение битов с ethertype при отсутствии 
                                 //второго vlan тега

  //дефайны для третьего vlan тега
`define VLAN2_POS 2               //во втором слове может находиться vlan1/ethertype
`define VLANTPID2_BITS_POS 47:32  //расположение битов с TPID vlan0 в слове
`define VLANID2_BITS_POS   63:48  //расположение битов с VLAN ID vlan0 в слове

//`define ETHTYPE1_BITS_POS  15:0  //расположение битов с ethertype при отсутствии 
                                 //второго vlan тега

  //дефайны для поля ethertype
`define ETHTYPE0_POS 1           //если нет vlan, то ethertype находится в первом слове
`define ETHTYPE0_BITS_POS 47:32  //битовая позиция в данном слове

`define ETHTYPE1_POS 2          //если есть один vlan, то ethertype находится во втором слове
`define ETHTYPE1_BITS_POS 15:0  //битовая позиция в данном слове
                                //если есть два vlan, то ethertype находится во втором слове
`define ETHTYPE2_BITS_POS 47:32 //битовая позиция в данном слове

`define ETHTYPE3_POS 3          //если есть три vlan, то ethertype находится во третьем слове
`define ETHTYPE3_BITS_POS 15:0  //битовая позиция в данном слове

