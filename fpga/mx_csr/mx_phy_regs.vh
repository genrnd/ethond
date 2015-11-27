/*
  CSR для управления физическими интерфейсами MX ( EX, EG ) 
*/

/* CONTROL REGISTERS */

`define MX_PHY_VER 16'h0_0_0_1


// MDIO controller control register
`define MDIO_CR       0                  
        // MDIO controller async. reset  
        `define MDIO_CR_RST    0     

        // 0->1 start one transaction     
        `define MDIO_CR_RUN    1  

        // two bits of code of operation field       
        `define MDIO_CR_COP_B0 2          
        `define MDIO_CR_COP_B1 3
        
        // if 1, now is loading fw in vitesse
        `define MDIO_CR_FW     4          

// MDIO frame PHYAD field
`define MDIOPHYAD_CR  1                   
        `define MDIOPHYAD_CR_PHYAD_B0 0
        `define MDIOPHYAD_CR_PHYAD_B4 4

// MDIO frame DEVAD field
`define MDIODEVAD_CR  2                   
        `define MDIODEVAD_CR_DEVAD_B0 0
        `define MDIODEVAD_CR_DEVAD_B4 4

// MDIO data to send; все 16 бит
`define MDIODATALO_CR 3                   

// MDIO clock divider coeff.
`define MDIODIV_CR    4                  
        // It defines MDC freq. 
        // MDIOspeed = clk_i/DIV
        `define MDIODIV_CR_DIV_B0 0       
        `define MDIODIV_CR_DIV_B5 5       

// регистры для загрузки прошивки
// в трансивер vitesse
`define VSC_FW_MN_CR       5               
        // 0->1 strob для сброса модуля fw_load
        `define VSC_FW_MN_CR_RST     0    

        // 0->1 strob для записи в fifo
        `define VSC_FW_MN_CR_RUN     1      

`define VSC_FW_W0_CR       6
`define VSC_FW_W1_CR       7

// контрольный регистр трансиверов
`define TRX_CR             8 
        // сброс трансивера EG; активный уровень - ноль
        `define TRX_CR_EG_NRST   0  
        
        // coma mode EG; активный уровень - единица
        `define TRX_CR_EG_COMA   1
        
        // сброс трансивера EX
        `define TRX_CR_EX_NRST   2 
        
        // выключение передачи на EX 
        `define TRX_CR_EX_TX_DIS 3
                                    
// выбор скорости 
`define PORT_SPEED_CR 9 
        // 0000 - 10Gb/s
        // 1001 - 10Mb/s; 
        // 1010 - 100 Mb/s; 
        // 1100 - 1000 Mb/s
        `define PORT_SPEED_CR_RX_SPEED_B0  0  
        `define PORT_SPEED_CR_RX_SPEED_B3  3
        
        `define PORT_SPEED_CR_TX_SPEED_B0  4  
        `define PORT_SPEED_CR_TX_SPEED_B3  7
        

// управление какими-то ледами
`define LED_CR 10 
        `define LED_CR_ALRM   0
        `define LED_CR_RX     1
        `define LED_CR_TEST   2


`define RST_ENGINE_CR 11
        // асинхронный сброс application logic в fpga
        `define RST_ENGINE_CR_MAIN_RST      0

        // сигнал только для tb, что можно генерить 
        // пакеты. Засунули в этот регистр, т.к.
        // жалко еще регистр на это тратить.
        `define RST_ENGINE_CR_TB_GEN_PKT_EN 15


`define MX_PHY_CR_CNT 12 

/* STATUS REGISTERS */

`define MX_PHY_VER_SR 0

// MDIO controller status registers
`define MDIO_SR       1                  
        // MDIO is busy 
        `define MDIO_SR_BUSY       0      
        
        // MDIO received data is valid
        `define MDIO_SR_DATAVAL    1    

        // fifo for loading fw in vitesse
        // is not empty
        `define MDIO_SR_FW_BUSY    2      
                                          
// MDIO received data; все 16 бит
`define MDIODATALO_SR 2                   

`define TRX_SR 3
        `define TRX_SR_EX_ABS   0
        
        `define TRX_SR_EX_LOS   1 
        
        `define TRX_SR_EX_TXFLT 2
        
        `define TRX_SR_EX_LOPC  3


`define MX_PHY_SR_CNT 4

