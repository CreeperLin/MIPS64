/*CPU*/
`include "def.v"
`ifdef SIM
`include "cpu_core.v"
`include "mmu_uart.v"
`include "mem_ctrl_uart.v"
`include "uart_comm.v" 
`endif
module riscv_cpu
#(
    parameter CORE = 1,
    parameter RPORT = CORE * 2,
    parameter WPORT = CORE
)
(
    input clk_in, btnC,
    input Rx,
    output Tx,
    input btnU,
    output reg[10:0] disp_out,
    output [15:0] led_out
);
wire clk;
//wire rst;
//assign rst = btnC;
reg rst;
reg rst_delay;
`ifndef SIM
clk_wiz_0 clk_wiz(clk, rst, 1'b0, clk_in);
`else
assign clk = clk_in;
`endif
/*(*mark_debug = "true"*)*/wire[RPORT * `RW_E_L] co_re;
/*(*mark_debug = "true"*)*/wire[WPORT * `RW_E_L] co_we;
wire[RPORT * `RW_LEN_L] co_rlen;
wire[WPORT * `RW_LEN_L] co_wlen;
wire[RPORT * `C_DATA_L] co_din;
wire[WPORT * `C_DATA_L] co_dout;
wire[RPORT * `M_ADDR_L] co_raddr;
wire[WPORT * `M_ADDR_L] co_waddr;
/*(*mark_debug = "true"*)*/wire[RPORT-1:0] co_rack;
/*(*mark_debug = "true"*)*/wire[WPORT-1:0] co_wack;

wire[`C_DATA_L] data_in;
wire[`C_DATA_L] data_out;
wire[`M_ADDR_L] read_addr;
wire[`M_ADDR_L] write_addr;
/*(*mark_debug = "true"*)*/wire c_re, c_we;
wire[`RW_LEN_L] c_rlen,c_wlen;
/*(*mark_debug = "true"*)*/wire m_rack, m_wack;

wire[`M_DATA_L] u_send, u_recv;
/*(*mark_debug = "true"*)*/wire u_re, u_se, u_rack, u_sack, u_ra, u_sa;

cpu_core core0(clk,rst,co_din[2*`C_DATA_L],co_dout[`C_DATA_L],
    co_raddr[2*`M_ADDR_L],co_waddr[`M_ADDR_L],
    co_re[2 * `RW_E_L],co_we[`RW_E_L],co_rlen[2*`RW_LEN_L],co_wlen[`RW_LEN_L],co_rack,co_wack/*led_out[3:0],*/,btnU);
//mmu mmu(clk,rst,data_in,data_out,read_addr,write_addr,c_re,c_we,m_rack,m_wack,
mmu_uart mmu_u(clk,rst,data_in,data_out,read_addr,write_addr,c_re,c_we,c_rlen,c_wlen,m_rack,m_wack,
    co_dout,co_din,co_raddr,co_waddr,co_re,co_we,co_rlen,co_wlen,co_rack,co_wack);

mem_ctrl_uart mctrl_u(clk,rst,u_recv,u_send,u_re,u_se,u_rack,u_sack,u_ra,u_sa,data_out,data_in,read_addr,write_addr,c_re,c_we,c_rlen,c_wlen,m_rack,m_wack);
uart_comm#(.ID(1), .BAUDRATE(`BAUD_RATE), .CLOCKRATE(`CLK_RATE)) uart(clk,rst,u_se,u_send,u_re,u_recv,u_sack,u_rack,u_sa,u_ra,Tx,Rx);
assign led_out[15] = clk;
assign led_out[14] = rst;
assign led_out[13] = Rx;
assign led_out[12] = Tx;
assign led_out[11] = co_re[0];
assign led_out[10] = co_rack[0];
assign led_out[9] = c_re;
assign led_out[8] = c_we;
assign led_out[7] = co_we;
assign led_out[6] = co_wack;
assign led_out[5] = m_rack;
assign led_out[4] = m_wack;
assign led_out[3] = u_se;
assign led_out[2] = u_sa;
assign led_out[1] = u_sack;
assign led_out[0] = u_ra;

always @(posedge clk or posedge btnC) begin
    if (btnC) begin
        rst_delay <= 1;
        rst <= 1;
        disp_out <= 11'b0111_1001111;
    end else begin
        rst_delay <= 0;
        rst <= rst_delay;
        disp_out <= 11'b1011_0010010;
    end
end
endmodule
