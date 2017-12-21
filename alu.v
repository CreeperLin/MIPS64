/*ALU*/
`include "alu_opcode.v"
module alu 
#(
    parameter OPR_L = 32,
    parameter ST_L = 3,
    parameter ALUOP_L = 5
)
(
    input clk, rst,
    input[OPR_L-1:0] A, B,
    input c,
    input[ALUOP_L-1:0] op,
    output reg[OPR_L-1:0] Y,
    output reg[ST_L-1:0] st
);
always @(posedge clk or posedge rst) begin
    if (rst) begin
        Y <= 0;
        st <= 0;
    end else begin

    end
end
always @(A or B) begin
case(op)
    `ALU_PASS:  Y <= (A==0)?B:A;
    `ALU_ADD:   Y <= A + B;
    `ALU_ADDC:  Y <= A + B + c;
    `ALU_SUB:   Y <= A - B;
    `ALU_SUBU:  Y <= A - B;
    `ALU_SUBB:  Y <= A - B - c;
    `ALU_INC:   Y <= A + 1;
    `ALU_DEC:   Y <= A - 1;
    `ALU_AND:   Y <= A & B;
    `ALU_OR:    Y <= A | B;
    `ALU_NOR:   Y <= ~(A | B);
    `ALU_XOR:   Y <= A ^ B;
    `ALU_SLL:   Y <= A << B[4:0];
    `ALU_SRL:   Y <= A >> B[4:0];
    `ALU_SLA:   Y <= $signed(A) <<< B[4:0];
    `ALU_SRA:   Y <= $signed(A) >>> B[4:0];
    `ALU_SLR:   Y <= (A << B[4:0]) | (A >> (32 - B[4:0]));
    `ALU_SRR:   Y <= (A >> B[4:0]) | (A << (32 - B[4:0]));
    `ALU_SEQ:   Y <= (A == B) ? 32'b1 : 32'b0;
    `ALU_SLT:   Y <= ($signed(A) < $signed(B)) ? 32'b1 : 32'b0;
    `ALU_SLTU:  Y <= (A < B) ? 32'b1 : 32'b0;
    `ALU_NEG:   Y <= ~A + 1;
    `ALU_NOT:   Y <= ~A;
    `ALU_MULT:  begin
    end
    `ALU_DIV: begin

    end
    default: $display("ALU:Unknown OP:%d",op);
endcase
end
endmodule
