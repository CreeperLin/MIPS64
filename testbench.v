`include "cpu.v"
`include "ram.v"
`include "mem_ctrl.v"

module testbench;
parameter MADDR_L = 32;
parameter M_DATA_L = 8;
parameter C_DATA_L = 32;
reg fclk, clk, rst;
wire[M_DATA_L-1:0] m_din, m_dout;
wire[M_DATA_L-1:0] c_din, c_dout;
wire[MADDR_L-1:0] c_waddr, c_raddr;
wire[MADDR_L-1:0] m_waddr, m_raddr;
wire m_re, m_we, c_re, c_we, c_rack, c_wack, m_rack, m_wack;
riscv_cpu cpu(clk, rst, c_din, c_dout, c_raddr, c_waddr,c_re,c_we,c_rack,c_wack);
mem_ctrl mctrl(clk, rst, m_dout,m_din,m_raddr,m_waddr,m_re,m_we,m_rack,m_wack,
    c_dout,c_din,c_raddr,c_waddr,c_re,c_we,c_rack,c_wack);
ram mem(clk, rst, m_din, m_dout, m_raddr, m_waddr, m_re, m_we, m_rack, m_wack);

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,cpu);
    $dumpvars(0,mem);
    $dumpvars(0,mctrl);
    rst = 1;
    #100;
    //repeat(100) #1 clk=!clk;
    rst = 0;
    //forever #1 fclk=!fclk;
    repeat(100000) #1 fclk=!fclk;
    //#500000;
    //$display("CPU TIMEOUT");
    //$finish;
end
endmodule
