`include "main.v"

module mipstest;
reg [1024:0] mem;
reg [64:0] inst;
wire [64:0] out;
mips64 m1(mem,out);
initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,m1);
    mem = 18'b01_01001101_00101111;
    
    $display("mips64 out:%d",out);
end
endmodule
