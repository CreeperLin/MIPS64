`include "main.v"
`include "ram.v"

module mipstest;
parameter MADDR_L = 32;
parameter DIN_L = 65;
parameter DOUT_L = 64;
wire[DOUT_L-1:0] dataout;
wire[DIN_L-1:0] datain;
wire[MADDR_L-1:0] addr;

RAM mem(addr, dataout[1:64], dataout[0], datain);
MIPS64 cpu(addr, datain, dataout);
initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,cpu);
    
    $display("mips64 out:%d",dataout);
end
endmodule
