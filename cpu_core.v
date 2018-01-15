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
//`define CACHE_E_
`include "def.v"
`ifdef SIM
`include "buffer.v"
`include "regfile.v"
`include "pipeIF.v"
`include "pipeID.v"
`include "pipeEX.v"
`include "pipeMA.v"
`include "pipeWB.v"
`include "b_predictor.v"
`ifdef CACHE_E_
`include "cache.v"
`endif
`endif
/*Components*/
module cpu_core
#(
    parameter R_PORT = 2,
    parameter W_PORT = 1
)
(
    input clk, rst,
    input[R_PORT*`C_DATA_L] co_din,
    output[W_PORT*`C_DATA_L] co_dout,
    output[R_PORT*`M_ADDR_L] co_raddr,
    output[W_PORT*`M_ADDR_L] co_waddr,
    output[R_PORT*`RW_E_L] co_re,
    output[W_PORT*`RW_E_L] co_we,
    output[R_PORT*`RW_LEN_L] co_rlen,
    output[W_PORT*`RW_LEN_L] co_wlen,
    input[R_PORT-1:0] co_rack,
    input[W_PORT-1:0] co_wack
    ,output[3:0] led
    ,input sig_on
);
localparam BUF_SZ_0 = 5;
localparam BUF_SZ_1 = 5;
localparam BUF_SZ_2 = 5;
localparam BUF_SZ_3 = 5;
localparam BUF_L_0 = 64;
localparam BUF_L_1 = 156;
localparam BUF_L_2 = 74;
localparam BUF_L_3 = 38;

wire[3:0] buf_re, buf_we, buf_av, buf_fu, buf_rack,buf_wack;
//assign led[0] = buf_we[0];
//assign led[1] = buf_we[1];
//assign led[2] = buf_we[2];
//assign led[3] = buf_we[3];


wire[BUF_L_0-1:0] buf_i0,buf_o0;
wire[BUF_L_1-1:0] buf_i1,buf_o1;
wire[BUF_L_2-1:0] buf_i2,buf_o2;
wire[BUF_L_3-1:0] buf_i3,buf_o3;

buffer#(.BUF_ID(0),.ADDR_L(BUF_SZ_0),.DATA_L(BUF_L_0))buf0(clk,rst,buf_re[0],buf_we[0],buf_i0,buf_o0,buf_rack[0],buf_wack[0],buf_av[0],buf_fu[0]);
buffer#(.BUF_ID(1),.ADDR_L(BUF_SZ_1),.DATA_L(BUF_L_1))buf1(clk,rst,buf_re[1],buf_we[1],buf_i1,buf_o1,buf_rack[1],buf_wack[1],buf_av[1],buf_fu[1]);
buffer#(.BUF_ID(2),.ADDR_L(BUF_SZ_2),.DATA_L(BUF_L_2))buf2(clk,rst,buf_re[2],buf_we[2],buf_i2,buf_o2,buf_rack[2],buf_wack[2],buf_av[2],buf_fu[2]);
buffer#(.BUF_ID(3),.ADDR_L(BUF_SZ_3),.DATA_L(BUF_L_3))buf3(clk,rst,buf_re[3],buf_we[3],buf_i3,buf_o3,buf_rack[3],buf_wack[3],buf_av[3],buf_fu[3]);

//reg[31:0] pc;
//wire[4:0] p_syn;

wire[4:0] reg_r_idx, reg_w_idx;
wire[31:0] reg_din, reg_dout;
wire reg_re,reg_we,reg_rack,reg_wack;
regfile gpr(clk,rst,reg_r_idx,reg_w_idx,
    reg_re,reg_we,reg_rack,reg_wack,reg_din,reg_dout);

wire[31:0] IF_inst,IF_pc;
wire[31:0] EX_nxpc;
wire EX_jp_e;

localparam BP_TAG_L = 10;
localparam BP_LHLEN = 8;
localparam BP_GHLEN = 12;
wire bp_t_out, bp_we, bp_wack, bp_t_in;
wire[BP_TAG_L-1:0] bp_tag_q, bp_tag_in;
b_predictor#(.TAG_LEN(BP_TAG_L),.LOCAL_HLEN(BP_LHLEN),.GLOBAL_HLEN(BP_GHLEN))
bp(clk,rst,bp_we,bp_wack,bp_tag_in,bp_t_in,bp_tag_q,bp_t_out);

wire[R_PORT*`C_DATA_L] ca_dout;
wire[W_PORT*`C_DATA_L] ca_din;
wire[R_PORT*`M_ADDR_L] ca_raddr;
wire[W_PORT*`M_ADDR_L] ca_waddr;
wire[R_PORT*`RW_E_L] ca_re;
wire[W_PORT*`RW_E_L] ca_we;
wire[R_PORT*`RW_LEN_L] ca_rlen;
wire[W_PORT*`RW_LEN_L] ca_wlen;
wire[R_PORT-1:0] ca_rack;
wire[W_PORT-1:0] ca_wack;

wire[`C_DATA_L] c0_plh0;
wire c0_plh1;
wire[1:0] c0_plh2; 

`ifdef CACHE_E_
cache#(.ID(0),.WORD_B(2),.IDX_B(5),.SET(2))
c0(clk,rst,/*ca_din[`C_DATA_L]*/ 0,ca_dout[`C_DATA_L],
    ca_raddr[`M_ADDR_L],/*ca_waddr[`M_ADDR_L]*/ 32'b0,
    ca_re[`RW_E_L],/*ca_we[`RW_E_L]*/ 1'b0,
    ca_rlen[`RW_LEN_L],/*ca_wlen[`RW_LEN_L]*/ 2'b0,
    ca_rack[0],c0_plh1,
    co_din[`C_DATA_L],/*co_dout[`C_DATA_L]*/c0_plh0,
    co_raddr[`M_ADDR_L],/*co_waddr[`M_ADDR_L]*/c0_plh0,
    co_re[`RW_E_L],/*co_we[`RW_E_L]*/c0_plh1,
    co_rlen[`RW_LEN_L],/*co_wlen[`RW_LEN_L]*/c0_plh2,
    co_rack[0],1'b0);

cache#(.ID(1),.WORD_B(3),.IDX_B(5),.SET(2))
c1(clk,rst,ca_din[`C_DATA_L],ca_dout[2*`K_C_DATA_L-1:1*`K_C_DATA_L],
    ca_raddr[2*`K_M_ADDR_L-1:1*`K_M_ADDR_L],ca_waddr[`M_ADDR_L],
    ca_re[1],ca_we[`RW_E_L],
    ca_rlen[3:2],ca_wlen[`RW_LEN_L],
    ca_rack[1],ca_wack[0],
    co_din[2*`K_C_DATA_L-1:1*`K_C_DATA_L],co_dout[`C_DATA_L],
    co_raddr[2*`K_C_DATA_L-1:1*`K_C_DATA_L],co_waddr[`M_ADDR_L],
    co_re[1],co_we[`RW_E_L],
    co_rlen[3:2],co_wlen[`RW_LEN_L],
    co_rack[1],co_wack);
`endif

wire IF_jp_ack;

pipeIF pIF(clk,rst,sig_on,buf_we[0],buf_wack[0],buf_fu[0],
    EX_jp_e,EX_nxpc,IF_jp_ack,
`ifdef CACHE_E_
    ca_dout[`C_DATA_L],ca_raddr[`M_ADDR_L],ca_re[`RW_E_L],ca_rlen[`RW_LEN_L],ca_rack[0],
`else
    co_din[`C_DATA_L],co_raddr[`M_ADDR_L],co_re[`RW_E_L],co_rlen[`RW_LEN_L],co_rack[0],
`endif
    buf_i0[63:32],buf_i0[31:0],bp_tag_q,bp_t_out,led[3]);

//assign buf_i0 = {IF_inst,IF_pc};
wire[4:0] EX_fwd_idx, MA_fwd_idx;
wire[31:0] EX_fwd_val, MA_fwd_val;
wire MA_ack,EX_ack;
assign MA_ack = buf_we[3];
assign EX_ack = buf_we[2];
//wire[6:0] ID_op;
//wire[4:0] ID_alu_op;
//wire ID_alu_c;
//wire[4:0] ID_rd;
//wire[31:0] ID_pc, ID_opr1, ID_opr2, ID_val;
//wire ID_jp_e,ID_br_e,ID_wb_e;
//wire[1:0] ID_rw_e;
//wire[1:0] ID_rw_len;
pipeID pID(clk,rst,buf_av[0],buf_re[0],buf_we[1],buf_rack[0],buf_wack[1],
    buf_o0[63:32],buf_o0[31:0],buf_i1[31:0],reg_re,reg_rack,reg_r_idx,reg_dout,
    buf_i1[155:151],buf_i1[150],
    buf_i1[149:145],buf_i1[144:140],buf_i1[139:135],
    buf_i1[134:103],buf_i1[102:71],buf_i1[70:39],
    buf_i1[38],buf_i1[37],buf_i1[36],buf_i1[35:34],buf_i1[33:32],
    MA_fwd_idx,MA_fwd_val,
    EX_fwd_idx,EX_fwd_val,MA_ack,EX_ack);

//assign buf_i1 = {ID_alu_op,ID_alu_c,
    //ID_rd,ID_rs1,ID_rs2,ID_opr1,ID_opr2,ID_val,
    //ID_jp_e,ID_br_e,ID_wb_e,ID_rw_e,ID_rw_len,ID_pc};

//wire[31:0] EX_ans,EX_dout;
//wire EX_wb_e;
//wire[4:0] EX_wb_idx;
//wire[1:0] EX_rw_e;
//wire[1:0] EX_rw_len;
pipeEX pEX(clk,rst,buf_av[1],buf_re[1],buf_we[2],buf_rack[1],buf_wack[2],
    buf_o1[31:0],buf_o1[155:151],buf_o1[150],
    buf_o1[149:145],buf_o1[144:140],buf_o1[139:135],
    buf_o1[134:103],buf_o1[102:71],buf_o1[70:39],
    buf_i2[73:42],buf_i2[41:10],
    buf_o1[35:34],buf_o1[33:32],buf_i2[3:2],buf_i2[1:0],
    buf_o1[36],buf_i2[9],buf_i2[8:4],
    buf_o1[38],buf_o1[37],EX_jp_e,EX_nxpc,IF_jp_ack,
    bp_tag_in,bp_t_in,bp_we,bp_wack,
    MA_fwd_idx,MA_fwd_val,MA_ack,
    EX_fwd_idx,EX_fwd_val);

//assign buf_i2 = {EX_ans,EX_dout,EX_wb_e,EX_wb_idx,EX_rw_e,EX_rw_len};

//wire MA_wb_e;
//wire[4:0] MA_wb_idx;
//wire[31:0] MA_wb_out;
pipeMA pMA(clk,rst,buf_av[2],buf_re[2],buf_we[3],buf_rack[2],buf_wack[3],/*MA_ack,*/
    buf_o2[3:2],buf_o2[1:0],
    buf_o2[73:42],buf_o2[41:10],
`ifdef CACHE_E_
    ca_dout[2*`K_C_DATA_L-1:1*`K_C_DATA_L],ca_din[`C_DATA_L],
    ca_raddr[2*`K_M_ADDR_L-1:1*`K_M_ADDR_L],ca_waddr[`M_ADDR_L],
    ca_re[1],ca_we[`RW_E_L],ca_rlen[2*2-1:1*2],ca_wlen[`RW_LEN_L],
    ca_rack[1],ca_wack[0],
`else
    co_din[2*`K_C_DATA_L-1:1*`K_C_DATA_L],co_dout[`C_DATA_L],co_raddr[2*`K_M_ADDR_L-1:1*`K_M_ADDR_L],co_waddr[`M_ADDR_L],co_re[1],co_we[`RW_E_L],co_rlen[2*2-1:1*2],co_wlen[`RW_LEN_L],co_rack[1],co_wack[0],
`endif
    buf_o2[9],buf_i3[37],buf_o2[8:4],buf_i3[36:32],buf_i3[31:0],
    MA_fwd_idx,MA_fwd_val);

//assign buf_i3 = {MA_wb_e,MA_wb_idx,MA_wb_out};

pipeWB pWB(clk,rst,buf_av[3],buf_re[3],buf_rack[3],
    buf_o3[37],buf_o3[31:0],reg_din,buf_o3[36:32],reg_w_idx,reg_we,reg_wack);

always @(posedge clk or posedge rst) begin
    if (rst) begin

    end else begin

    end
end

endmodule
