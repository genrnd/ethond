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


module delay_sv
#(
parameter WIDTH  = 1,
parameter CYCLES = 1

)(
  input      [WIDTH-1:0]  d,
  input                   clk,
  input                   rst,
  input                   ena,
  output reg [WIDTH-1:0]  q
);

reg [CYCLES-1:0][WIDTH-1:0] delay = '0;

generate
if (CYCLES == 0)
  assign q = d;
else if (CYCLES == 1)
  begin
    always @( posedge clk or posedge rst )
      if( rst )
        q <= '0;
      else
        if( ena )
          q <= d;
  end
else if (CYCLES == 2)
begin
  always @( posedge clk or posedge rst )
    if( rst )
      delay <= '0;
    else
      if( ena )
        begin
          delay[0] <= d;
          delay[1] <= delay[0];
        end

    assign q = delay[1];
end
else
begin
    always @( posedge clk or posedge rst )
      if( rst )
        begin
          delay <= '0;
        end
      else
        if( ena )
          begin
            delay[CYCLES-1:1] <= delay[CYCLES-2:0];
            delay[0]          <= d;
          end

      assign q = delay[CYCLES-1];
  end
endgenerate
endmodule
