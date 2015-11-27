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

module sedge_sel_sv(
  input ain,
  input Clk,
  output edg
);

reg ain_d1,ain_d2,ain_d3;
always @(posedge Clk)
begin
  ain_d1 <= ain;
  ain_d2 <= ain_d1;
  ain_d3 <= ain_d2;
end

assign edg = ain_d2 & ~ain_d3;

endmodule
