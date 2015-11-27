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

module mdio(
  input         clk_i,
  input         rst_i,
  input         run_i,      //start transaction
  input  [1:0]  cop_i,      //code of operation
  input  [4:0]  phyaddr_i,  //phy address to send
  input  [4:0]  devaddr_i,  //devadr to send
  input  [15:0] data_i,     //data or address to send
  input         md_i,       //serial data input
  input  [5:0]  divider_i,  //clock divider coeeff for mdc_o
  output        md_o,       //serial data output
  output        mdoen_o,    //output enable for tri state buffer
  output logic  mdc_o,      //serial data clock output 
  output [15:0] data_o,     //received data
  output        busy_o,     //busyness 
  output logic  data_val_o  //received data valideness
);

parameter ST      = 2'b00;         //start delimeter 
parameter PREAMB  = 32'hFFFFFFFF;  //preambule
parameter TA      = 2'b10;         //turn around bits

//FSM states
parameter idle_s     = 2'b00;
parameter mdcalign_s = 2'b01;
parameter send_s     = 2'b10;
parameter rcv_s      = 2'b11;

logic [1:0] state;
logic [1:0] next_state;

logic 	     loadsendreg;          //load shift register with data to send
logic        shiftsendreg;         //enable data shift in send register
logic [63:0] senddata_reg;         //shift register with data to send 
logic [5:0]  bitscntr;             //counter of sent bits (mdc cycles)
logic [5:0]  mdc_cnt;              //counter for one mdc cycle
 
logic        shiftrcvreg;          //shift enable for receive register
logic [17:0] rcvdata_reg;          //received data register (incl. TA bits)

logic        startofbit;           //start  of bit pulse
logic        midofbit;             //middle of bit pulse
logic        mdc_r;                //delayed mcd_o

assign shiftrcvreg = midofbit & (state == rcv_s);
assign data_o      = rcvdata_reg[15:0];
assign busy_o      = (state != idle_s);

always_ff @(posedge clk_i, posedge rst_i)
begin: valid_output
if( rst_i )
  data_val_o <= 1'b0;
else
  if( ( state != idle_s ) && ( next_state == idle_s ) )
    data_val_o <= 1'b1; 
  else
    if( run_i ) 
      data_val_o <= 1'b0;
end: valid_output

always_ff @(posedge clk_i, posedge rst_i)
begin: rcvshift_reg
if(rst_i)
  rcvdata_reg <= '0;
else
  if(shiftrcvreg)
    rcvdata_reg <= {rcvdata_reg[16:0],md_i};
end: rcvshift_reg

always_ff @(posedge clk_i, posedge rst_i)
begin: mdc_delay
  if(rst_i)
    mdc_r <= 1'b0;
  else
    mdc_r <= mdc_o;
end: mdc_delay

assign startofbit =  mdc_r &  ~mdc_o;
assign midofbit   = ~mdc_r &  mdc_o;

assign mdoen_o    = (state == send_s);

always_ff @(posedge clk_i, posedge rst_i)
begin: bits_counter
  if(rst_i)
    bitscntr <= '0;
  else 
    if((state == idle_s) || (state == mdcalign_s))
      bitscntr <= '0;
    else
      if(startofbit)
        bitscntr <= bitscntr + 6'd1;
end: bits_counter


always_ff @(posedge clk_i, posedge rst_i)
begin: state_register
  if(rst_i)
    state <= idle_s;
  else
    state <= next_state;
end: state_register

always_comb
begin: next_state_logic
  next_state = state;
  case(state)
    idle_s:
      begin
        if(run_i)
	  next_state = mdcalign_s;
        else
          next_state = idle_s;
      end

    mdcalign_s:
      if(startofbit)
        next_state = send_s;
      else
        next_state = mdcalign_s;

    send_s:
      begin
        if(~cop_i[1]) //OP == 00 or 01 ("address" or "write" frame)
	  if((bitscntr == 6'd63) & startofbit)  //number of sent bits
            next_state = idle_s;
          else
	    next_state = send_s;
        else          //OP == 10 OR 11 ("read" or "read increment" frame)
          if((bitscntr == 6'd45) & startofbit) //it's time to receive data
	    next_state = rcv_s;
          else
            next_state = send_s;
      end

    rcv_s:
      begin
        if((bitscntr == 6'd63) & startofbit)  //number of bits in frame
          next_state = idle_s;
        else
	  next_state = rcv_s;
      end

    default:
      begin
        next_state = idle_s;
      end

  endcase
end: next_state_logic
  
always_ff @(posedge clk_i, posedge rst_i)
begin: mdc_counter
  if(rst_i)
    mdc_cnt <= '0;
  else
    if(mdc_cnt == (divider_i - 6'd1))
      mdc_cnt <= '0;
    else
      mdc_cnt <= mdc_cnt + 6'd1;
end: mdc_counter

always_ff @(posedge clk_i, posedge rst_i)
begin: mdc_output
  if(rst_i)
    mdc_o <= 1'b0;
  else
    if(mdc_cnt == '0)
      mdc_o <= 1'b0;
    else
      if(mdc_cnt == (divider_i>>1) ) //divider's half
        mdc_o <= 1'b1;
end: mdc_output

//assign loadsendreg  = run_i;
assign loadsendreg  = (state == mdcalign_s) && (next_state == send_s);
assign shiftsendreg = startofbit & (state == send_s);
assign md_o         = senddata_reg[63]; 

always_ff @(posedge clk_i, posedge rst_i)
begin: sendshift_reg
  if(rst_i)
    senddata_reg <= '0;
  else
    if(loadsendreg)
      senddata_reg <= {PREAMB,ST,cop_i,phyaddr_i,devaddr_i, TA, data_i};
    else
      if(shiftsendreg)
        senddata_reg <= (senddata_reg << 1);
end: sendshift_reg

endmodule


    


