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
        * Addressing Modes:
            * Register
            * Immediates
        * Cache?
    * Extras:
        * Branch Prediction
*/

/*Components*/
module REG(idx, op, val, out);

endmodule

module MEM(addr, op, val, out);

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

