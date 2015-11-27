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

// оригинальный модуль MAC_rx_ctrl
module gbe_rx_mac_ctrl_simple #(
  parameter RX_IFG_SET = 12,
  parameter RX_MIN_LEN = 64,
  parameter RX_MAX_LEN = 9600
)
(
  
  input        clk_i,
  input        clk_en_i,

  input        rst_i,
  
  input  [7:0] rx_d_i,
  input        rx_dv_i,
  input        rx_err_i,
  
  output [7:0] fifo_data_o,
  output       fifo_data_en_o,
  output       fifo_data_err_o,
  output       fifo_data_end_o,
  input        fifo_full_i,

  output       crc_err_o

);

enum int unsigned {
  IDLE_S,          
  PREAMBLE_S,      
  SFD_S,           
  DATA_S,          
  CHECK_CRC_S,      
  OK_END_S,         
  DROP_S,          
  ERR_END_S,        
  CRC_ERR_END_S,     
  FIFO_FULL_DROP_S,    
  FIFO_FULL_ERR_END_S,  
  IFG_S           
} state, next_state; 

logic [5:0] ifg_cnt;   

logic       rx_dv_d1;

logic [7:0] rx_d_d1;
logic [7:0] rx_d_d2;

logic       rx_err_d1; 
logic       rx_err_d2;

logic       too_long;
logic       too_short;

logic       crc_err;

always_ff @( posedge clk_i or posedge rst_i )                 
  if( rst_i ) 
    begin  
      rx_dv_d1    <= '0;

      rx_d_d1     <= '0;                                                            
      rx_d_d2     <= '0;

      rx_err_d1   <= '0;
      rx_err_d2   <= '0; 
    end
  else
    if( clk_en_i )
      begin  
        rx_dv_d1  <= rx_dv_i;

        rx_d_d1   <= rx_d_i;                                                            
        rx_d_d2   <= rx_d_d1;

        rx_err_d1 <= rx_err_i;
        rx_err_d2 <= rx_err_d1; 
      end

//******************************************************************************
//State_machine                                                           
//******************************************************************************
                                                    
always_ff @( posedge clk_i or posedge rst_i )                 
  if( rst_i )                                          
    state <= IDLE_S;                   
  else
    if( clk_en_i )
      state <= next_state;                   
                                                        
always_comb
  begin
    next_state = state;

    case( state )
      IDLE_S:
        begin
          if( rx_dv_d1 && ( rx_d_d1 == 8'h55 ) )                
            next_state = PREAMBLE_S;    
        end

      PREAMBLE_S:                            
        begin
          if( !rx_dv_d1 )                        
            next_state = ERR_END_S;      
          else 
            if( rx_err_d2 )                     
              next_state = DROP_S;        
            else 
              if( rx_d_d1 == 8'hd5 )                 
                next_state = SFD_S;                 
              else 
                if( rx_d_d1 == 8'h55 )                
                  next_state = state;     
                else                                
                  next_state = DROP_S;        
        end

      SFD_S:                                 
        begin
          if( !rx_dv_d1 )                        
            next_state = ERR_END_S;      
          else 
            if( rx_err_d2 )                     
              next_state = DROP_S;        
            else                                
              next_state = DATA_S;       
        end

      DATA_S:
        begin
          if( !rx_dv_d1 && ( !too_short ) && ( !too_long ) )
            next_state = CHECK_CRC_S;   
          else 
            if( !rx_dv_d1 && ( too_short || too_long ) )
              next_state = ERR_END_S;
            else 
              if( fifo_full_i )
                next_state = FIFO_FULL_ERR_END_S;
              else 
                if( rx_err_d2 || too_long )
                  next_state = DROP_S;        
        end

      CHECK_CRC_S:
        begin
          if( crc_err )
             next_state = CRC_ERR_END_S;
          else  
             next_state = OK_END_S;
        end

      DROP_S:
        begin
          if( !rx_dv_d1 )                        
            next_state  = ERR_END_S;      
        end

      OK_END_S:      next_state  = IFG_S;         
      
      ERR_END_S:     next_state  = IFG_S;       
      
      CRC_ERR_END_S: next_state  = IFG_S;   

      FIFO_FULL_DROP_S:
        begin
          if( !rx_dv_d1 )                        
            next_state = IFG_S;     
        end

      FIFO_FULL_ERR_END_S: next_state  = FIFO_FULL_DROP_S;                                        

      IFG_S:
        begin // remove some additional time     
          if( ifg_cnt == ( RX_IFG_SET - 4 ) )   
            next_state = IDLE_S;        
        end
                                                  
      default: next_state = IDLE_S;        
    endcase
  end

always_ff @ ( posedge clk_i or posedge rst_i )
  if( rst_i )                                          
    ifg_cnt <= '0;   
  else
    if( clk_en_i )
      begin
        if( state != IFG_S )
          ifg_cnt <= '0;                                
        else 
          ifg_cnt <= ifg_cnt + 1'b1;
      end

//******************************************************************************
//gen fifo interface signals                                                     
//******************************************************************************                     

assign fifo_data_o     = rx_d_d2;       

assign fifo_data_en_o  = ( state == DATA_S );

assign fifo_data_end_o = ( state == ERR_END_S           ) ||
                         ( state == OK_END_S            ) ||
                         ( state == CRC_ERR_END_S       ) ||
                         ( state == FIFO_FULL_ERR_END_S );

assign fifo_data_err_o = ( state == ERR_END_S           ) ||
                         ( state == FIFO_FULL_ERR_END_S );



logic [15:0] frame_len;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    frame_len <= 0;
  else 
    if( clk_en_i )
      begin
        if( state == SFD_S )
          frame_len <= 16'd1;
        else 
          if( ( state == DATA_S ) && ( frame_len != '1 ) )
            frame_len <= frame_len + 1'd1;
      end

assign too_short = ( frame_len < RX_MIN_LEN );
assign too_long  = ( frame_len > RX_MAX_LEN );

//******************************************************************************
//CRC_chk interface                                               
//****************************************************************************** 
logic             crc_en;
logic             crc_init;
logic             crc_err_reg;

assign crc_en    = ( state == DATA_S );
assign crc_init  = ( state == SFD_S  );

assign crc_err_o = crc_err_reg;

always @( posedge clk_i or posedge rst_i )
  if( rst_i )
    crc_err_reg <= 1'b0;
  else
    if( clk_en_i )
      begin
        if( crc_init )
          crc_err_reg <= 1'b0;
        else 
          if( state == CHECK_CRC_S )
            crc_err_reg <= crc_err;
      end
        
CRC_chk U_CRC_chk(
  .Clk                        ( clk_i        ),
  .clkeni                     ( clk_en_i     ),
  .Reset                      ( rst_i        ),

  .CRC_data                   ( fifo_data_o  ),
  .CRC_init                   ( crc_init     ),
  .CRC_en                     ( crc_en       ),

  .CRC_chk_en                 (  1'b1        ),
  .CRC_err                    ( crc_err      )
);

endmodule
