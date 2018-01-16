`include "def.v"
`ifdef SIM
`include "ram_uart.v"
`include "cpu_uart.v"
`endif

module testbench;
reg clk, rst, run;
wire Rx, Tx;
wire[15:0] led;
wire[10:0] disp;
riscv_cpu cpu(clk, rst, Rx, Tx, run, disp, led);
ram_uart mem(clk, rst, Rx, Tx);
initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,cpu);
    $dumpvars(0,mem);
    rst = 0;
    run = 0;
    clk = 0;
    rst = 1;
    repeat(100) #1 clk=!clk;
    rst = 0;
    repeat(100) #1 clk=!clk;
    run = 1;
    //repeat(10000) #1 clk=!clk;
    forever #1 clk=!clk;
end
endmodule
