/*CPU*/
`include "def.v"
`include "cpu_core.v"
`include "mmu.v"
//`include "mem_ctrl.v"
module riscv_cpu
#(
    parameter CORE = 1,
    parameter RPORT = CORE * 2,
    parameter WPORT = CORE
)
(
    input clk, rst,
    input[`M_DATA_L] data_in,
    output[`M_DATA_L] data_out,
    output[`M_ADDR_L] read_addr,
    output[`M_ADDR_L] write_addr,
    output c_re, c_we,
    input m_rack, m_wack
);
//wire[DATA_L-1:0] c1_din;
//wire[DATA_L-1:0] c1_dout;
//wire[`M_ADDR_L] c1_raddr;
//wire[`M_ADDR_L] c1_waddr;
//mem_ctrl mctrl(data_in,data_out,read_addr,write_addr,c1_din,c1_dout,c1_raddr,c1_waddr);
//cpu_core core1(c1_din,c1_dout,c1_raddr,c1_waddr);
wire[RPORT * `RW_E_L] co_re;
wire[WPORT * `RW_E_L] co_we;
wire[RPORT * `RW_LEN_L] co_rlen;
wire[WPORT * `RW_LEN_L] co_wlen;
wire[RPORT * `C_DATA_L] co_din;
wire[WPORT * `C_DATA_L] co_dout;
wire[RPORT * `M_ADDR_L] co_raddr;
wire[WPORT * `M_ADDR_L] co_waddr;
wire[RPORT-1:0] co_rack;
wire[WPORT-1:0] co_wack;
cpu_core core0(clk,rst,co_din[2*`C_DATA_L],co_dout[`C_DATA_L],
    co_raddr[2*`M_ADDR_L],co_waddr[`M_ADDR_L],
    co_re[2 * `RW_E_L],co_we[`RW_E_L],co_rlen[2*`RW_LEN_L],co_wlen[`RW_LEN_L],co_rack,co_wack);
mmu mmu1 (clk,rst,data_in,data_out,read_addr,write_addr,c_re,c_we,m_rack,m_wack,
    co_dout,co_din,co_raddr,co_waddr,co_re,co_we,co_rlen,co_wlen,co_rack,co_wack);

always @(posedge clk or posedge rst) begin
    if (rst) begin

    end else begin

    end
end

endmodule
