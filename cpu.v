/*CPU*/
`include "cpu_core.v"
`include "mmu.v"
//`include "mem_ctrl.v"
module riscv_cpu
#(
    parameter M_DATA_L = 8,
    parameter C_DATA_L = 32,
    parameter MADDR_L = 32
)
(
    input clk, rst,
    input[M_DATA_L-1:0] data_in,
    output[M_DATA_L-1:0] data_out,
    output[MADDR_L-1:0] read_addr,
    output[MADDR_L-1:0] write_addr,
    output c_re, c_we
);
//wire[DATA_L-1:0] c1_din;
//wire[DATA_L-1:0] c1_dout;
//wire[MADDR_L-1:0] c1_raddr;
//wire[MADDR_L-1:0] c1_waddr;
//mem_ctrl mctrl(data_in,data_out,read_addr,write_addr,c1_din,c1_dout,c1_raddr,c1_waddr);
//cpu_core core1(c1_din,c1_dout,c1_raddr,c1_waddr);
wire co_re, co_we;
wire[1:0] co_rlen, co_wlen;
wire[C_DATA_L-1:0] co_din, co_dout;
wire[MADDR_L-1:0] co_raddr, co_waddr;
cpu_core core1(clk,rst,co_din,co_dout,co_raddr,co_waddr,co_re,co_we,co_rlen,co_wlen);
mmu mmu1(clk,rst,data_in,data_out,read_addr,write_addr,c_re,c_we,co_dout,co_din,co_raddr,co_waddr,co_re,co_we,co_rlen,co_wlen);

always @(posedge clk or posedge rst) begin
    if (rst) begin

    end else begin

    end
end

endmodule
