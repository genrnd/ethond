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

interface etnsoc_if;

  logic        clk;
  logic        rst;

  logic        csr_waitrequest;
  logic [31:0] csr_readdata;
  logic        csr_readdatavalid;
  logic [0:0]  csr_burstcount;
  logic [31:0] csr_writedata;
  logic [12:0] csr_address;
  logic        csr_write;
  logic        csr_read;
  logic [3:0]  csr_byteenable;
  logic        csr_debugaccess;


modport soc(
  input    clk,
  output   rst,    

  input    csr_waitrequest,                     
  input    csr_readdata,                        
  input    csr_readdatavalid,                   
  output   csr_burstcount,                      
  output   csr_writedata,                       
  output   csr_address,                         
  output   csr_write,                           
  output   csr_read,                            
  output   csr_byteenable,                      
  output   csr_debugaccess                     
);


modport app(

  output   clk,
  input    rst,      

  output   csr_waitrequest,                     
  output   csr_readdata,                        
  output   csr_readdatavalid,                   
  input    csr_burstcount,                      
  input    csr_writedata,                       
  input    csr_address,                         
  input    csr_write,                           
  input    csr_read,                            
  input    csr_byteenable,                      
  input    csr_debugaccess                     

);

endinterface
