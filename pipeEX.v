`include "alu.v"
module pipeEX
#(
    parameter ALUOP_L = 5,
    parameter REG_SZ = 32
)
(
    input clk, rst,
    input up_syn,
    output reg up_ack,
    output reg down_syn,
    input down_ack,
   
    input[ALUOP_L-1:0] alu_op,
    input[4:0] rd,
    input signed[REG_SZ-1:0] opr1, opr2, val,
    output signed[REG_SZ-1:0] ans,
    
    //control
    output signed[REG_SZ-1:0] dout,
    output re, we,
    output[1:0] rlen, wlen,
    output reg wb_e, jp_e,
    output reg[REG_SZ-1:0] nxpc
);
wire c;
wire[2:0] st;
assign c = 0;
assign dout = val;
alu alu1(clk,rst,opr1,opr2,c,alu_op,ans,st);
always @(posedge clk or posedge rst) begin
    if (rst) begin
        wb_e <= 0;
        jp_e <= 0;
        up_ack <= 0;
        down_syn <=0;
    end else begin

    end
end
always @(posedge up_syn) begin
    #1;
    up_ack = 1;
    #3;
    $display("EX: alu_op:%d rd:%d opr1:%d opr2:%d ans:%d",alu_op,rd,opr1,opr2,ans);
    wb_e = 1;
    down_syn = 1;
end
always @(negedge up_syn) begin
    up_ack <= #1 0;
end
always @(posedge down_ack) begin
    down_syn <= #1 0;
end
endmodule
