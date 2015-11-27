`define UDP_PROT 8'd17
`define TCP_PROT 8'd6

`define IP_SRC_2B_POS 2
`define IP_SRC_6B_POS 2

`define IP_DST_2B_POS 2
`define IP_DST_6B_POS 3


`define IP_SRC_6B_B0 47:40
`define IP_SRC_6B_B1 39:32
`define IP_SRC_6B_B2 31:24
`define IP_SRC_6B_B3 23:16

`define IP_SRC_2B_B0 15:8
`define IP_SRC_2B_B1 7:0
`define IP_SRC_2B_B2 63:56
`define IP_SRC_2B_B3 55:48

`define IP_DST_2B_B0 47:40
`define IP_DST_2B_B1 39:32
`define IP_DST_2B_B2 31:24
`define IP_DST_2B_B3 23:16

`define IP_DST_6B_B0 15:8
`define IP_DST_6B_B1 7:0
`define IP_DST_6B_B2 63:56
`define IP_DST_6B_B3 55:48

`define IP_VER_POS 0

`define IP_VER_6B 55:52
`define IP_VER_2B 23:20

`define IP_TOS_POS 0

`define IP_TOS_6B 63:56
`define IP_TOS_2B 31:24

`define IP_PROT_POS 1

`define IP_PROT_6B 63:56
`define IP_PROT_2B 31:24

//flags_offset
`define IP_FLOFF_POS 1

`define IP_FLOFF_6B_B0 47:40
`define IP_FLOFF_6B_B1 39:32

`define IP_FLOFF_2B_B0  15:8
`define IP_FLOFF_2B_B1   7:0

//packet identification
`define IP_IDENT_6B_POS  1
`define IP_IDENT_2B_POS  0

`define IP_IDENT_6B_B0 31:24
`define IP_IDENT_6B_B1 23:16

`define IP_IDENT_2B_B0  63:56
`define IP_IDENT_2B_B1  55:48

//packet identification
`define IP_LEN_POS 0

`define IP_HEAD_LEN_6B 51:48
`define IP_HEAD_LEN_2B 19:16

`define L4_START_6B_POS 3
`define L4_START_2B_POS 2


// IP checksum

`define IP_CHKSUM_2B_POS 1
`define IP_CHKSUM_6B_POS 2 

`define IP_CHKSUM_2B_B0 47:40
`define IP_CHKSUM_2B_B1 39:32

`define IP_CHKSUM_6B_B0 15:8
`define IP_CHKSUM_6B_B1 7:0

