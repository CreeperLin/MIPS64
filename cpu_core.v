/*
* RISC-V 32I ISA:
    * Stages:
        * IF
        * ID
        * EX
        * MA
        * WB
    * Features:
        * Pipelining
			* Buffer
        * Addressing Modes:
            * Register
            * Immediates
        * Cache?
		* Interrupts?
		* Page?
    * Extras:
        * Branch Prediction
*/

`include "buffer.v"
`include "cache.v"
`include "regfile.v"
`include "pipeIF.v"
`include "pipeID.v"
`include "pipeEX.v"
`include "pipeMA.v"
`include "pipeWB.v"
/*Components*/
module cpu_core
#(
    parameter MADDR_L = 32,
    parameter DATA_L = 32
)
(
    input clk, rst,
    input[DATA_L-1:0] core_din,
    output[DATA_L-1:0] core_dout,
    output[MADDR_L-1:0] core_raddr,
    output[MADDR_L-1:0] core_waddr,
    output co_re, co_we,
    output[1:0] co_rlen, co_wlen
);
localparam BUF_SZ_0 = 5;
localparam BUF_SZ_1 = 5;
localparam BUF_SZ_2 = 5;
localparam BUF_SZ_3 = 5;

//reg[31:0] pc;
wire[4:0] p_ack;
wire[4:0] p_syn;

wire[DATA_L-1:0] mh_dout[1:0];
wire[DATA_L-1:0] mh_din[1:0];
wire[MADDR_L-1:0] mh_raddr[1:0];
wire[MADDR_L-1:0] mh_waddr[1:0];
wire mh_re[1:0];
wire mh_we[1:0];
wire[1:0] mh_rlen[1:0];
wire[1:0] mh_wlen[1:0];

wire[4:0] reg_r_idx, reg_w_idx;
wire[31:0] reg_din, reg_dout;
wire reg_re,reg_we;
regfile gpr(clk,rst,reg_r_idx,reg_w_idx,reg_re,reg_we,reg_din,reg_dout);

wire[31:0] IF_inst;
wire[31:0] EX_nxpc;
wire EX_jp_e;

wire[3:0] buf_re, buf_we, buf_em, buf_fu;

localparam BUF_L_0 = 32;
wire[BUF_L_0-1:0] buf_i0,buf_o0;
localparam BUF_L_1 = 64;
wire[BUF_L_1-1:0] buf_i1,buf_o1;
localparam BUF_L_2 = 64;
wire[BUF_L_2-1:0] buf_i2,buf_o2;
localparam BUF_L_3 = 64;
wire[BUF_L_3-1:0] buf_i3,buf_o3;

buffer#(.BUF_ID(0),.ADDR_L(BUF_SZ_0),.DATA_L(BUF_L_0))buf0(clk,rst,buf_re[0],buf_we[0],buf_i0,buf_o0,buf_em[0],buf_fu[0]);
buffer#(.BUF_ID(1),.ADDR_L(BUF_SZ_1),.DATA_L(BUF_L_1))buf1(clk,rst,buf_re[1],buf_we[1],buf_i1,buf_o1,buf_em[1],buf_fu[1]);
buffer#(.BUF_ID(2),.ADDR_L(BUF_SZ_2),.DATA_L(BUF_L_2))buf2(clk,rst,buf_re[2],buf_we[2],buf_i2,buf_o2,buf_em[2],buf_fu[2]);
buffer#(.BUF_ID(3),.ADDR_L(BUF_SZ_3),.DATA_L(BUF_L_3))buf3(clk,rst,buf_re[3],buf_we[3],buf_i3,buf_o3,buf_em[3],buf_fu[3]);

pipeIF pIF(clk,rst,p_syn[0],p_ack[0],p_syn[1],p_ack[1],
    EX_jp_e,EX_nxpc,core_din,core_raddr,co_re,co_rlen,IF_inst);

wire[6:0] ID_op;
wire[4:0] ID_alu_op;
wire[4:0] ID_rd;
wire[31:0] ID_opr1, ID_opr2, ID_val;
wire ID_re, ID_we;
wire[1:0] ID_rlen,ID_wlen;
pipeID pID(clk,rst,p_syn[1],p_ack[1],p_syn[2],p_ack[2],
    IF_inst,reg_re,reg_r_idx,reg_dout,
    ID_op,ID_alu_op,ID_rd,ID_opr1,ID_opr2,ID_val,ID_re,ID_we,ID_rlen,ID_wlen);

wire[31:0] EX_ans,EX_dout;
wire EX_wb_e;
pipeEX pEX(clk,rst,p_syn[2],p_ack[2],p_syn[3],p_ack[3],
    ID_alu_op,ID_rd,ID_opr1,ID_opr2,ID_val,EX_ans,EX_dout,
    ID_re,ID_we,ID_rlen,ID_wlen,
    EX_wb_e,EX_jp_e,EX_nxpc);
wire MA_wb_e;
wire[4:0] MA_wb_idx;
wire[31:0] MA_wb_out;
pipeMA pMA(clk,rst,p_syn[3],p_ack[3],p_syn[4],p_ack[4],
    ID_re,ID_we,ID_rlen,ID_wlen,
    ID_rd,EX_ans,EX_dout,
    mh_din[1],mh_dout[1],mh_raddr[1],mh_waddr[1],mh_re[1],mh_we[1],mh_rlen[1],mh_wlen[1],
    EX_wb_e,MA_wb_e,MA_wb_idx,MA_wb_out);
pipeWB pWB(clk,rst,p_syn[4],p_ack[4],p_syn[0],p_ack[0],
    MA_wb_out,reg_din,MA_wb_idx,reg_w_idx,reg_we);

always @(posedge clk or posedge rst) begin
    if (rst) begin

    end else begin

    end
end

endmodule
