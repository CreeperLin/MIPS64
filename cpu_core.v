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
`include "def.v"
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
    parameter R_PORT = 2,
    parameter W_PORT = 1
)
(
    input clk, rst,
    input[R_PORT*`C_DATA_L] core_din,
    output[W_PORT*`C_DATA_L] core_dout,
    output[R_PORT*`M_ADDR_L] core_raddr,
    output[W_PORT*`M_ADDR_L] core_waddr,
    output[R_PORT*`RW_E_L] co_re,
    output[W_PORT*`RW_E_L] co_we,
    output[R_PORT*`RW_LEN_L] co_rlen,
    output[W_PORT*`RW_LEN_L] co_wlen
);
localparam BUF_SZ_0 = 5;
localparam BUF_SZ_1 = 5;
localparam BUF_SZ_2 = 5;
localparam BUF_SZ_3 = 5;
localparam BUF_L_0 = 32;
localparam BUF_L_1 = 64;
localparam BUF_L_2 = 64;
localparam BUF_L_3 = 64;

wire[3:0] buf_re, buf_we, buf_em, buf_fu;

wire[BUF_L_0-1:0] buf_i0,buf_o0;
wire[BUF_L_1-1:0] buf_i1,buf_o1;
wire[BUF_L_2-1:0] buf_i2,buf_o2;
wire[BUF_L_3-1:0] buf_i3,buf_o3;

buffer#(.BUF_ID(0),.ADDR_L(BUF_SZ_0),.DATA_L(BUF_L_0))buf0(clk,rst,buf_re[0],buf_we[0],buf_i0,buf_o0,buf_em[0],buf_fu[0]);
buffer#(.BUF_ID(1),.ADDR_L(BUF_SZ_1),.DATA_L(BUF_L_1))buf1(clk,rst,buf_re[1],buf_we[1],buf_i1,buf_o1,buf_em[1],buf_fu[1]);
buffer#(.BUF_ID(2),.ADDR_L(BUF_SZ_2),.DATA_L(BUF_L_2))buf2(clk,rst,buf_re[2],buf_we[2],buf_i2,buf_o2,buf_em[2],buf_fu[2]);
buffer#(.BUF_ID(3),.ADDR_L(BUF_SZ_3),.DATA_L(BUF_L_3))buf3(clk,rst,buf_re[3],buf_we[3],buf_i3,buf_o3,buf_em[3],buf_fu[3]);

//reg[31:0] pc;
wire[4:0] p_ack;
wire[4:0] p_syn;

wire[4:0] reg_r_idx, reg_w_idx;
wire[31:0] reg_din, reg_dout;
wire reg_re,reg_we;
regfile gpr(clk,rst,reg_r_idx,reg_w_idx,reg_re,reg_we,reg_din,reg_dout);

wire[31:0] IF_inst,IF_pc;
wire[31:0] EX_nxpc;
wire EX_jp_e;

pipeIF pIF(clk,rst,p_syn[0],p_ack[0],p_syn[1],p_ack[1],
    EX_jp_e,EX_nxpc,core_din[`C_DATA_L],core_raddr[`M_ADDR_L],co_re[`RW_E_L],co_rlen[`RW_LEN_L],IF_inst,IF_pc);

wire[6:0] ID_op;
wire[4:0] ID_alu_op;
wire ID_alu_c;
wire[4:0] ID_rd;
wire[31:0] ID_pc, ID_opr1, ID_opr2, ID_val;
wire ID_jp_e,ID_br_e,ID_wb_e;
wire[1:0] ID_rw_e;
wire[1:0] ID_rw_len;
pipeID pID(clk,rst,p_syn[1],p_ack[1],p_syn[2],p_ack[2],
    IF_inst,IF_pc,ID_pc,reg_re,reg_r_idx,reg_dout,
    ID_op,ID_alu_op,ID_alu_c,ID_rd,ID_opr1,ID_opr2,ID_val,
    ID_jp_e,ID_br_e,ID_wb_e,
    ID_rw_e,ID_rw_len);

wire[31:0] EX_ans,EX_dout;
wire EX_wb_e;
wire[1:0] EX_rw_e;
wire[1:0] EX_rw_len;
pipeEX pEX(clk,rst,p_syn[2],p_ack[2],p_syn[3],p_ack[3],
    ID_pc,ID_alu_op,ID_alu_c,ID_rd,ID_opr1,ID_opr2,ID_val,
    EX_ans,EX_dout,
    ID_rw_e,ID_rw_len,EX_rw_e,EX_rw_len,
    ID_wb_e,EX_wb_e,
    ID_jp_e,ID_br_e,EX_jp_e,EX_nxpc);
wire MA_wb_e;
wire[4:0] MA_wb_idx;
wire[31:0] MA_wb_out;
pipeMA pMA(clk,rst,p_syn[3],p_ack[3],p_syn[4],p_ack[4],
    EX_rw_e,EX_rw_len,
    ID_rd,EX_ans,EX_dout,
    core_din[2*`K_C_DATA_L-1:1*`K_C_DATA_L],core_dout[`C_DATA_L],core_raddr[2*`K_M_ADDR_L-1:1*`K_M_ADDR_L],core_waddr[`M_ADDR_L],co_re[1],co_we[`RW_E_L],co_rlen[2*2-1:1*2],co_wlen[`RW_LEN_L],
    EX_wb_e,MA_wb_e,MA_wb_idx,MA_wb_out);

pipeWB pWB(clk,rst,p_syn[4],p_ack[4],p_syn[0],p_ack[0],
    MA_wb_e,MA_wb_out,reg_din,MA_wb_idx,reg_w_idx,reg_we);

always @(posedge clk or posedge rst) begin
    if (rst) begin

    end else begin

    end
end

endmodule
