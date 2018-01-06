/*mem controller(North Bridge)*/
module mem_ctrl
#(
    parameter C_DATA_L = 8,
    parameter M_DATA_L = 8,
    parameter MADDR_L = 32
)
(
    input clk, rst,
    input[M_DATA_L-1:0] m_din,
    output[M_DATA_L-1:0] m_dout,
    output[MADDR_L-1:0] m_raddr,
    output[MADDR_L-1:0] m_waddr,
    output m_re,
    output m_we,
    input m_rack, m_wack,
    
    input[C_DATA_L-1:0] c_din,
    output[C_DATA_L-1:0] c_dout,
    input[MADDR_L-1:0] c_raddr,
    input[MADDR_L-1:0] c_waddr,
    input c_re, c_we,
    output c_rack, c_wack
);

assign m_dout = c_din;
assign m_raddr = c_raddr;
assign m_waddr = c_waddr;
assign c_dout = m_din;
assign m_re = c_re;
assign m_we = c_we;
assign c_rack = m_rack;
assign c_wack = m_wack;
endmodule
