`include "cpu.v"
`include "ram.v"
`include "mem_ctrl.v"

module testbench;
parameter MADDR_L = 32;
parameter M_DATA_L = 8;
parameter C_DATA_L = 32;
reg clk, rst;
wire[M_DATA_L-1:0] m_din, m_dout;
wire[M_DATA_L-1:0] c_din, c_dout;
wire[MADDR_L-1:0] c_waddr, c_raddr;
wire[MADDR_L-1:0] m_waddr, m_raddr;
wire m_re, m_we, c_re, c_we;
riscv_cpu cpu(clk, rst, c_din, c_dout, c_raddr, c_waddr,c_re,c_we);
mem_ctrl mctrl(clk, rst, m_dout,m_din,m_raddr,m_waddr,m_re,m_we,c_dout,c_din,c_raddr,c_waddr,c_re,c_we);
ram mem(clk, rst, m_din, m_dout, m_raddr, m_waddr, m_re, m_we);

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,cpu);
    $dumpvars(0,mem);
    $dumpvars(0,mctrl);
    rst = 0;
    clk = 0;
    rst = 1;
    //repeat(100) #1 clk=!clk;
    #100;
    rst = 0;
    //forever #1 clk=!clk;
    //repeat(200) #1 clk=!clk;
    #10000;
    $finish;
end
endmodule
