`ifndef DEFINE_H_
`define DEFINE_H_

`define SIM

`define K_C_DATA_L   32
`define K_M_DATA_L   8
`define K_M_ADDR_L   32

`define C_DATA_L    32-1:0
`define M_DATA_L    8-1:0
`define M_ADDR_L    32-1:0
`define RW_E_L      1-1:0
`define RW_LEN_L    2-1:0
`define PC_L        32-1:0
`define REG_L       32-1:0

`define BAUD_RATE   5000000
`define CLK_RATE    66667000
//`define BAUD_RATE   115200
//`define CLK_RATE    100000000

`define LOG2(x) \
	((x <= 0)		? -1 : \
	(x == 1)		? 0 : \
	(x < 4) 		? 1 : \
	(x < 8) 		? 2 : \
	(x < 16) 		? 3 : \
	(x < 32)		? 4 : \
	(x < 64)		? 5 : \
	(x < 128)		? 6 : \
	(x < 256)		? 7 : \
	(x < 512)		? 8 : \
	(x < 1024)		? 9 : \
	(x < 2048)		? 10 : \
	(x < 4096)		? 11 : \
	(x < 8192)		? 12 : \
	(x < 16384)	    ? 13 : \
	(x < 32768)	    ? 14 : \
	(x < 65536)	    ? 15 : \
	(x < 131072)	? 16 : \
	(x < 262144)	? 17 : \
	(x < 524288)	? 18 : \
	(x < 1048576)	? 19 : -1)
`endif
