`include "buffer.v"
module test;
reg clk,rst,re,we;
reg[15:0] din;
wire[15:0] dout;
wire em,fu;
buffer#(.BUF_ID(0),.ADDR_L(5),.DATA_L(16)) b1(clk,rst,re,we,din,dout,em,fu);
integer i;
initial begin
    rst = 0;
    rst = 1;
    rst = #1 0;
    din = 0;
    for (i=0;i<40;i=i+1) begin
        din[10:0] = $random;
        we = 1;
        we = #1 0;
        $display("dbg w %d",din);
    end

    for (i=0;i<20;i=i+1) begin
        re = 1;
        re = #1 0;
        $display("dbg r %d",dout);
    end
end
endmodule
