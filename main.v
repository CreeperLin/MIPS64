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
module Cache(addr, datain, dataout);
//2-way set associative
parameter CACHE_ROW = 64;
parameter CACHE_LEN = 64;
parameter MADDR_L = 32;
parameter OFS_L = 6;
parameter TAG_L = 21;
parameter IDX_L = 5;
parameter FLG_L = 1;
input[CACHE_LEN-1:0] datain;
input[MADDR_L-1:0] addr;
reg[CACHE_LEN-1:0] dataout;

reg[FLG_L+TAG_L-1:0] map1[CACHE_ROW/2-1:0];
reg[CACHE_LEN-1:0] data1[CACHE_ROW/2-1:0];
reg[FLG_L+TAG_L-1:0] map2[CACHE_ROW/2-1:0];
reg[CACHE_LEN-1:0] data2[CACHE_ROW/2-1:0];
wire[TAG_L-1:0] tag;
wire[IDX_L-1:0] idx;
wire[OFS_L-1:0] ofs;
assign tag = addr[MADDR_L-1:MADDR_L-TAG_L];
assign idx = addr[MADDR_L-TAG_L-1:OFS_L];
assign ofs = addr[OFS_L-1:0];
reg[FLG_L+TAG_L-1:0] key1;
reg[FLG_L+TAG_L-1:0] key2;
reg[CACHE_LEN-1:0] val1;
reg[CACHE_LEN-1:0] val2;
always @(addr) begin
    key1 <= map1[idx];
    key2 <= map2[idx];
    val1 <= data1[idx];
    val2 <= data2[idx];
end

always @(datain) begin
    data1[idx] <= datain;
    data2[idx] <= datain;
end
endmodule

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

reg[REG_SZ-1:0] gpreg[REG_NUM-1:0];
assign dout = gpreg[idx];
always @(posedge we) begin
    gpreg[idx] = din;
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
reg[1:0] i;
always @(pc) begin
    addr = pc[MADDR_L-1:0];
    for(i=0;i<4;i=i+1) begin
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
assign funct = inst[5:0];

6'b000000: ;//0: SLL
6'b000001: ;//1: 
6'b000010: ;//2: SRL
6'b000011: ;//3: SRA
6'b000100: ;//4: SLLV
6'b000101: ;
6'b000110: ;
6'b000111: ;
6'b001000: ;
6'b001001: ;
6'b001010: ;
6'b001011: ;
6'b001100: ;
6'b001101: ;
6'b001110: ;
6'b001111: ;
6'b010000: ;
6'b010001: ;
6'b010010: ;
6'b010011: ;
6'b010100: ;
6'b010101: ;
6'b010110: ;
6'b010111: ;
6'b100000: ;
6'b100001: ;
6'b100010: ;
6'b100011: ;
6'b100100: ;
6'b100101: ;
6'b100110: ;
6'b100111: ;
6'b101000: ;
6'b101001: ;
6'b101010: ;
6'b101011: ;
6'b101100: ;

endmodule

/*EX*/
module ALU(A, B, c, op, Y, st);
parameter OPR_L = 64;
parameter ST_L = 3;
input[OPR_L-1:0] A;
input[OPR_L-1:0] B;
input c;
input[5:0] op;
output[OPR_L-1:0] Y;
output[ST_L-1:0] st;

always @(A or B) begin
case(op)
6'b000000: Y = (A==0) ? B : A;//0: PASS
6'b000001: Y = {A[62:0],0};//1:SLL
6'b000010: Y = {0,A[63:1]};//2:SRL
6'b000011: Y = {A[63],A[61:0],0};
6'b000100: Y = {A[63,]}

default: $display("ALU:Unknown OP:%d",op);
endcase
end
endmodule

module EX(rs, rd, rt, immd, ans);

endmodule

/*WB*/
module WB(mem, addr, val);

endmodule

module MIPS64(addr, datain, dataout);
parameter MADDR_L = 32;
parameter DIN_L = 64;
parameter DOUT_L = 65;
input[DIN_L-1:0] datain;
output[DOUT_L-1:0] dataout;
output[MADDR_L-1:0] addr;


endmodule
