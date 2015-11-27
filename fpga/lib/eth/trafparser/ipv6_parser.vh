`define UDP_PROT 8'd17
`define TCP_PROT 8'd6

`define IPV6_VER_POS 0
`define IPV6_VER_6B 55:52
`define IPV6_VER_2B 23:20

`define IPV6_SRC_6B_POS 3
`define IPV6_SRC_6B_B0_B8  55:48
`define IPV6_SRC_6B_B1_B9  63:56
`define IPV6_SRC_6B_B2_B10  7:0
`define IPV6_SRC_6B_B3_B11  15:8
`define IPV6_SRC_6B_B4_B12  23:16
`define IPV6_SRC_6B_B5_B13  31:24
`define IPV6_SRC_6B_B6_B14  39:32
`define IPV6_SRC_6B_B7_B15  47:40

`define IPV6_SRC_2B_POS  3
`define IPV6_SRC_2B_B0_B8  23:16
`define IPV6_SRC_2B_B1_B9  31:24
`define IPV6_SRC_2B_B2_B10  39:32
`define IPV6_SRC_2B_B3_B11  47:40
`define IPV6_SRC_2B_B4_B12  55:48
`define IPV6_SRC_2B_B5_B13  63:56
`define IPV6_SRC_2B_B6_B14  7:0
`define IPV6_SRC_2B_B7_B15  15:8

`define IPV6_DST_6B_POS  5
`define IPV6_DST_2B_POS  5

`define IPV6_NH_6B_POS  1
`define IPV6_NH_6B_B0   39:32

`define IPV6_NH_2B_POS  1
`define IPV6_NH_2B_B0   7:0

`define L4_IPV6_START_6B_POS 5 
`define L4_IPV6_START_2B_POS 5
