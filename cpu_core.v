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
localparam BUF_SZ_0 = 15;
localparam BUF_SZ_1 = 15;
localparam BUF_SZ_2 = 15;
localparam BUF_SZ_3 = 15;
localparam BUF_L_0 = 64;
localparam BUF_L_1 = 146;
localparam BUF_L_2 = 74;
localparam BUF_L_3 = 38;

wire[3:0] buf_re, buf_we, buf_av, buf_fu;

wire[BUF_L_0-1:0] buf_i0,buf_o0;
wire[BUF_L_1-1:0] buf_i1,buf_o1;
wire[BUF_L_2-1:0] buf_i2,buf_o2;
wire[BUF_L_3-1:0] buf_i3,buf_o3;

buffer#(.BUF_ID(0),.ADDR_L(BUF_SZ_0),.DATA_L(BUF_L_0))buf0(clk,rst,buf_re[0],buf_we[0],buf_i0,buf_o0,buf_av[0],buf_fu[0]);
buffer#(.BUF_ID(1),.ADDR_L(BUF_SZ_1),.DATA_L(BUF_L_1))buf1(clk,rst,buf_re[1],buf_we[1],buf_i1,buf_o1,buf_av[1],buf_fu[1]);
buffer#(.BUF_ID(2),.ADDR_L(BUF_SZ_2),.DATA_L(BUF_L_2))buf2(clk,rst,buf_re[2],buf_we[2],buf_i2,buf_o2,buf_av[2],buf_fu[2]);
buffer#(.BUF_ID(3),.ADDR_L(BUF_SZ_3),.DATA_L(BUF_L_3))buf3(clk,rst,buf_re[3],buf_we[3],buf_i3,buf_o3,buf_av[3],buf_fu[3]);

//reg[31:0] pc;
wire[4:0] buf_ack;
//wire[4:0] p_syn;

wire[4:0] reg_r_idx, reg_w_idx;
wire[31:0] reg_din, reg_dout;
wire reg_re,reg_we;
regfile gpr(clk,rst,reg_r_idx,reg_w_idx,reg_re,reg_we,reg_din,reg_dout);

wire[31:0] IF_inst,IF_pc;
wire[31:0] EX_nxpc;
wire EX_jp_e;

wire sig_loop;

pipeIF pIF(clk,rst,sig_loop,buf_we[0],buf_ack[0],
    EX_jp_e,EX_nxpc,
    core_din[`C_DATA_L],core_raddr[`M_ADDR_L],co_re[`RW_E_L],co_rlen[`RW_LEN_L],
    buf_i0[63:32],buf_i0[31:0]);

//assign buf_i0 = {IF_inst,IF_pc};

//wire[6:0] ID_op;
wire[4:0] ID_alu_op;
wire ID_alu_c;
wire[4:0] ID_rd;
wire[31:0] ID_pc, ID_opr1, ID_opr2, ID_val;
wire ID_jp_e,ID_br_e,ID_wb_e;
wire[1:0] ID_rw_e;
wire[1:0] ID_rw_len;
pipeID pID(clk,rst,buf_av[0],buf_re[0],buf_we[1],buf_ack[1],
    buf_o0[63:32],buf_o0[31:0],ID_pc,reg_re,reg_r_idx,reg_dout,
    ID_alu_op,ID_alu_c,ID_rd,ID_opr1,ID_opr2,ID_val,
    ID_jp_e,ID_br_e,ID_wb_e,
    ID_rw_e,ID_rw_len);

assign buf_i1 = {ID_alu_op,ID_alu_c,
    ID_rd,ID_opr1,ID_opr2,ID_val,
    ID_jp_e,ID_br_e,ID_wb_e,ID_rw_e,ID_rw_len,ID_pc};

wire[31:0] EX_ans,EX_dout;
wire EX_wb_e;
wire[4:0] EX_wb_idx;
wire[1:0] EX_rw_e;
wire[1:0] EX_rw_len;
pipeEX pEX(clk,rst,buf_av[1],buf_re[1],buf_we[2],buf_ack[2],
    buf_o1[31:0],buf_o1[145:141],buf_o1[140],
    buf_o1[134:103],buf_o1[102:71],buf_o1[70:39],
    EX_ans,EX_dout,
    buf_o1[35:34],buf_o1[33:32],EX_rw_e,EX_rw_len,
    buf_o1[36],EX_wb_e,
    buf_o1[139:135],EX_wb_idx,
    buf_o1[38],buf_o1[37],EX_jp_e,EX_nxpc);

assign buf_i2 = {EX_ans,EX_dout,EX_wb_e,EX_wb_idx,EX_rw_e,EX_rw_len};

wire MA_wb_e;
wire[4:0] MA_wb_idx;
wire[31:0] MA_wb_out;
pipeMA pMA(clk,rst,buf_av[2],buf_re[2],buf_we[3],buf_ack[3],
    buf_o2[3:2],buf_o2[1:0],
    buf_o2[73:42],buf_o2[41:10],
    core_din[2*`K_C_DATA_L-1:1*`K_C_DATA_L],core_dout[`C_DATA_L],core_raddr[2*`K_M_ADDR_L-1:1*`K_M_ADDR_L],core_waddr[`M_ADDR_L],co_re[1],co_we[`RW_E_L],co_rlen[2*2-1:1*2],co_wlen[`RW_LEN_L],
    buf_o2[9],MA_wb_e,buf_o2[8:4],MA_wb_idx,MA_wb_out);

assign buf_i3 = {MA_wb_e,MA_wb_idx,MA_wb_out};

pipeWB pWB(clk,rst,buf_av[3],buf_re[3],sig_loop,
    buf_o3[37],buf_o3[31:0],reg_din,buf_o3[36:32],reg_w_idx,reg_we);

always @(posedge clk or posedge rst) begin
    if (rst) begin

    end else begin

    end
end

endmodule
