/*CPU*/
`include "def.v"
`include "cpu_core.v"
`include "mmu_uart.v"
`include "mem_ctrl_uart.v"
`include "uart_comm.v" 
module riscv_cpu
#(
    parameter CORE = 1,
    parameter RPORT = CORE * 2,
    parameter WPORT = CORE
)
(
    input clk, rst,
    input Rx,
    output Tx
);
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

wire[`C_DATA_L] data_in;
wire[`C_DATA_L] data_out;
wire[`M_ADDR_L] read_addr;
wire[`M_ADDR_L] write_addr;
wire c_re, c_we;
wire[`RW_LEN_L] c_rlen,c_wlen;
wire m_rack, m_wack;

wire[`M_DATA_L] u_send, u_recv;
wire u_re, u_se, u_rack, u_sack, u_ra, u_sa;

cpu_core core0(clk,rst,co_din[2*`C_DATA_L],co_dout[`C_DATA_L],
    co_raddr[2*`M_ADDR_L],co_waddr[`M_ADDR_L],
    co_re[2 * `RW_E_L],co_we[`RW_E_L],co_rlen[2*`RW_LEN_L],co_wlen[`RW_LEN_L],co_rack,co_wack);
//mmu mmu(clk,rst,data_in,data_out,read_addr,write_addr,c_re,c_we,m_rack,m_wack,
mmu_uart mmu_u(clk,rst,data_in,data_out,read_addr,write_addr,c_re,c_we,c_rlen,c_wlen,m_rack,m_wack,
    co_dout,co_din,co_raddr,co_waddr,co_re,co_we,co_rlen,co_wlen,co_rack,co_wack);

mem_ctrl_uart mctrl_u(clk,rst,u_recv,u_send,u_re,u_se,u_rack,u_sack,u_ra,u_sa,data_out,data_in,read_addr,write_addr,c_re,c_we,c_rlen,c_wlen,m_rack,m_wack);
uart_comm#(.ID(1), .BAUDRATE(5000000/*115200*/), .CLOCKRATE(66667000)) uart(clk,rst,u_se,u_send,u_re,u_recv,u_sack,u_rack,u_sa,u_ra,Tx,Rx);
always @(posedge clk or posedge rst) begin
    if (rst) begin

    end else begin

    end
end
endmodule
