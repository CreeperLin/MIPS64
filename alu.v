/*ALU*/
`include "alu_opcode.v"
module alu 
#(
    parameter OPR_L = 32,
    parameter ST_L = 3
)
(
    input clk, rst, run,
    input[OPR_L-1:0] A, B,
    input c,
    input[`ALUOP_L] op,
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
always @(posedge run) begin
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
    `ALU_SEQ:   Y <= (A == B) ? ~c : c;
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

module alu_mult_ctrl
#(
    parameter OPR_L = 32,
    parameter ALUOP_L = 5
)
(
    input clk,rst,
    input[OPR_L-1:0] A, B,
    
    output reg[OPR_L-1:0] alu_A, alu_B,
    output reg[ALUOP_L-1:0] alu_op,
    input[OPR_L-1:0] alu_Y,

    output reg[2*OPR_L-1:0] Y
);
//alu a1();
//fast add
reg[2*OPR_L-1:0] tmp;
integer i;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        alu_A <= 0;
        alu_B <= 0;
        alu_op <= 0;
        Y <= 0;
        tmp <= 0;
    end else begin
        tmp <= B;
        for (i=0;i<OPR_L;i=i+1) begin
            if (A[i]==1'b1) begin
                Y = Y + tmp;
                //alu_op = `ALU_ADD;
                //alu_A = tmp;
                //alu_B = Y;
                //#1;
                //Y = tmp;
            end
            tmp = tmp + tmp;
            //alu_op = `ALU_ADD;
            //alu_A = tmp;
            //alU_B = tmp;
            //#1;
            //tmp = alu_Y;
        end
    end
end

endmodule

module alu_div_ctrl
#(
    parameter OPR_L = 32,
    parameter ALUOP_L = 5
)
(
    input clk,rst,
    input[OPR_L-1:0] A, B,
    
    output reg[OPR_L-1:0] alu_A, alu_B,
    output reg[ALUOP_L-1:0] alu_op,
    input[OPR_L-1:0] alu_Y,

    output reg[OPR_L-1:0] Y
);

endmodule
