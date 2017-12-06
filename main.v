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
parameter REG_SZ = 64;
parameter REG_NUM = 32;
parameter BUF_W = 64;
parameter BUF_L = 16;
/*Components*/
module Buffer(we, re, din, dout);
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
module IF(mem, addr, inst);

endmodule

/*ID*/
module ID(inst, rs, rd, rt, immd);

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
