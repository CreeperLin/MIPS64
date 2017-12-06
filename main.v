/*
* MIPS64(Instruction Set Architecture):
    * Stages:
        * IF
        * ID
        * EX
        * MA
        * WB
    * Features:
        * Pipelining
			* Buffer
        * Addressing Modes:
            * Register
            * Immediates
        * Cache?
		* Interrupts?
		* Page?
    * Extras:
        * Branch Prediction
*/

`include "ram.v"

/*Components*/
module Buffer(we, re, din, dout);
parameter BUF_W = 64;
parameter BUF_L = 16;
input we,re;
input[BUF_W-1:0] din;
output[BUF_W-1:0] dout;

reg[BUF_W-1:0] buffer[BUF_L-1:0];
reg[3:0] tp;
assign tp = 0;
assign dout = buffer[tp];
always @(posedge we) begin
    buffer[tp] = din;
    tp = tp + 1;
end
always @(posedge re) begin
    dout = buffer[tp];
    tp = tp - 1;
end
endmodule

module REG(idx, we, din, dout);
parameter REG_SZ = 64;
parameter REG_NUM = 32;
input[6:0] idx;
input we;
input[REG_SZ-1:0] din;
output[REG_SZ-1:0] dout;

reg[REG_SZ-1:0] greg[REG_NUM-1:0];
assign dout = greg[idx];
always @(posedge we) begin
    greg[idx] = din;
end
endmodule

/*IF*/
module IF(pc, addr, datain, inst);
parameter INST_L = 32;
parameter PC_L = 32;
parameter MADDR_L = 32;
input[PC_L-1:0] pc;
input datain;
reg [MADDR_L-1:0] addr;
output[INST_L-1:0] inst;
integer i;
always @(pc) begin
    addr = pc[MADDR_L-1:0];
    for(i=0;i<32;i=i+1) begin
        inst[i] = datain;
        addr = addr + 1;
        //#1;
    end
end
endmodule

/*ID*/
module ID(inst, op, rs, rd, rt, immd);
input[31:0] inst;
output[5:0] op;
output[4:0] rs,rd,rt;
output[15:0] immd;
wire[5:0] shamt;
wire[5:0] funct;
assign op = inst[31:26];
assign rs = inst[25:21];
assign rd = inst[20:16];
assign rt = inst[15:11];
assign immd = inst[15:0];
assign shamt = inst[10:6];
assign funct = inst[5:0]
endmodule

/*EX*/
module ALU(A, B, C, op, Y, st);

endmodule

module EX(rs, rd, rt, immd, ans);

endmodule

/*WB*/
module WB(mem, addr, val);

endmodule

module MIPS64(in, out);

endmodule
