/*
  CSR для идентификации прошивки и её опционирования.

*/

/* CONTROL REGISTERS */

// прочитанные данные из ROM, где содержится
// информация по прошивке
`define FPGA_ID_RD_DATA_W0_CR 0
`define FPGA_ID_RD_DATA_W1_CR 1 

`define FPGA_ID_CR 2
        `define FPGA_ID_CR_RD_ADDR_B0   0
        `define FPGA_ID_CR_RD_ADDR_B7   7

// 24 битный ключ         
`define OPTS_USER_KEY_W0_CR 3
`define OPTS_USER_KEY_W1_CR 4
        `define OPTS_USER_KEY_W1_CR_KEY_B0 0
        `define OPTS_USER_KEY_W1_CR_KEY_B7 7

// 16 битный номер прибора/платы ( s/n )         
`define OPTS_USER_ID_CR 5

`define OPTS_CR 6
        // строб на активацию
        `define OPTS_CR_ACTIVATE_STB 0

`define MX_FPGA_ID_CR_CNT 7

/* STATUS REGISTERS */

// прочитанный набор опций, 16 бит
`define OPTS_RD_DATA_SR 0 

// статусный регистр для разблокировки опций 
`define OPTS_SR         1
        `define OPTS_SR_ACCEPTED 0

`define MX_FPGA_ID_SR_CNT 2

/*
  Чтение из ROM c идентификация прошивки:
    1. Выставляем адрес в 
         FPGA_ID_CR_RD_ADDR_B7/B0.

    2. Читаем 32-битные данные из 
         FPGA_ID_RD_DATA_W1_CR/W0_CR.

  Внимание:
    Регистры FPGA_ID_RD_DATA_W1_CR/W0_CR считаются контрольными,
    но по факту они статусные: если вы туда запишите, то прочитаете не
    то, что вы записали. Так сделано, что бы мы не зависили при чтении
    от количества контрольных регистров в этой фиче. 

  "Расшифровка" ключа пользователя -> разрешенные 
  маски опций:
    1. Ключ пользователя ( 24 бита ) записываем в
         OPTS_USER_KEY_W0_CR - младшие 16 бит
         OPTS_USER_KEY_W1_CR_KEY_B7/B0 - старшие 8 бит

    2. Номер прибора/платы в 
         OPTS_USER_ID_CR.

    3. Дергаем строб OPTS_CR_ACTIVATE_STB.

    4. Считываем маску разрешнных опций ( 16 бит ) из 
         OPTS_RD_DATA_SR

    5. Считываем, принялся ли ключ(?) в OPTS_SR_ACCEPTED

*/
