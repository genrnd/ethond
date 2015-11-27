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

package feat_anlz;

  
  
  function int port_bit_mask_to_offset( input int port_num, int port_bit_mask, int one_port_reg_cnt );
    int enable_port_cnt = 0;

    // если порт не включен - сразу возвращаем ноль, как такого оффсета нет
    if( port_bit_mask[ port_num ] == 0 )
      begin 
        return 0;
      end
    else
      begin
        // подсчитываем количество включенных портов ДО этого порта

        for( int i = 0; i < port_num; i++ )
          begin
            if( port_bit_mask[i] ) 
              enable_port_cnt += 1;  
          end

        return one_port_reg_cnt * enable_port_cnt;
      end
  endfunction
  

  // Превращаем битовую маску в количество портов, в которых есть фича фичи.

  /*
    NOTE:
      Я не знаю почему, но тривиальный код типа:
        int tmp;
        int z = 0;

        tmp = port_bit_mask;
        while( tmp != 0 )
          begin
            z   += ( tmp & 1 );
            tmp = tmp >> 1;
          end
        return z;

      ругается quartus'om, что значение localparam на которое я назначаю
      не константное: не дает собирать. ( Причем это был второй вариант реализации:
      первый был через цикл for ). Пришлось пока сделать все через case. Пока
      у нас два порта это не так критично, но все равно неприятно.
  */

  function int port_bit_mask_to_used_ports_cnt( input integer port_bit_mask );
    case( port_bit_mask )
      0:
        begin
          return 0;
        end
      1:
        begin
          return 1;
        end
      2:
        begin
          return 1;
        end
      3:
        begin
          return 2;
        end
      default:
        begin
          return 0;
        end
    endcase

  endfunction
  
  function int feature_port_bit_mask_sel( input integer feature_port_bit_mask = 0, int port_num );
    int z = 0;
    z = feature_port_bit_mask[ port_num ];
    return z;
  endfunction 

endpackage
