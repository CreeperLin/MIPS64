/*decoder*/
`include "riscv_const.v"
`include "alu_opcode.v"
module pipeID
#(
    parameter REG_SZ = 32,
    parameter ALUOP_L = 5
)
(
    input clk, rst,
    input up_syn,
    output reg up_ack,
    output reg down_syn,
    input down_ack,

    input[31:0] inst,
    output reg reg_re,
    output reg[4:0] reg_idx,
    input[REG_SZ-1:0] reg_in,
    //input[REG_SZ-1:0] pc_in,

    output[6:0] op,
    output reg[ALUOP_L-1:0] alu_op,
    output[4:0] rd,
    output reg signed[REG_SZ-1:0] opr1,opr2,val,
    //output reg signed[31:0] imm,
    output reg re, we,
    output reg[1:0] rlen, wlen
);
wire[4:0] shamt;
wire[6:0] funct7;
wire[2:0] funct3;
wire[4:0] rs1,rs2;
wire signed[31:0] imm_I, imm_S, imm_B, imm_U, imm_J;
assign imm_I = {{21{inst[31]}},inst[30:20]};
assign imm_S = {{21{inst[31]}},inst[30:25],inst[11:7]};
assign imm_B = {{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0};
assign imm_U = {inst[31:12],12'b0};
assign imm_J = {{11{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0};
assign op = inst[6:0];
assign rd = inst[11:7];
assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign shamt = inst[10:6];
assign funct7 = inst[31:25];
assign funct3 = inst[14:12];

task fetch_reg;
input[4:0] idx;
output[REG_SZ-1:0] dout;
begin
    reg_idx = idx;
    reg_re = 1;
    dout = reg_in;
    reg_re = #1 0;
end
endtask
always @(posedge clk or posedge rst) begin
    if (rst) begin
        up_ack <= 0;
        down_syn <=0;
        opr1 <= 0;
        opr2 <= 0;
        val <=0;
    end else begin

    end
end
always @(posedge up_syn) begin
    #1;
    up_ack = 1;
    //reg_idx = rs1;
    //reg_re = 1;
    //opr1 = reg_in;
    //reg_re = 0;
    case (op)
        `OP_LUI, `OP_AUIPC: begin
            opr2=imm_U;
        end
        `OP_JAL: begin
            opr1 = imm_J;
            opr2 = 4;
            val = imm_J;
        end
        `OP_JALR: begin
            fetch_reg(rs1,opr1);
            opr2=imm_I;
            val = 4;
        end
        `OP_OP_IMM: begin
            fetch_reg(rs1,opr1);
            opr2=imm_I;
            case (funct3)
                `FUNCT3_ADDI: alu_op = `ALU_ADD;
                `FUNCT3_SLLI: alu_op = `ALU_SLL;
                `FUNCT3_SRLI_SRAI: alu_op = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                `FUNCT3_XORI: alu_op = `ALU_XOR;
                `FUNCT3_SLTI: alu_op = `ALU_SLT;
                `FUNCT3_SLTIU: alu_op = `ALU_SLTU;
                `FUNCT3_ORI: alu_op = `ALU_OR;
                `FUNCT3_ANDI: alu_op = `ALU_AND;
                default: $display("ERROR:ID OP_OP");
            endcase
        end
        `OP_LOAD: begin
            fetch_reg(rs1,opr1);
            opr2=imm_I;
            case (funct3)
                `FUNCT3_LB,`FUNCT3_LBU: rlen = 2'b00;
                `FUNCT3_LH,`FUNCT3_LHU: rlen = 2'b01;
                `FUNCT3_LW: rlen = 2'b11;
            endcase
        end
        `OP_BRANCH: begin
            fetch_reg(rs1,opr1);
            fetch_reg(rs2,opr2);
            val=imm_B;
            case (funct3)
                `FUNCT3_BEQ, `FUNCT3_BNE: alu_op = `ALU_SEQ;
                `FUNCT3_BLT: alu_op = `ALU_SLT;
                `FUNCT3_BLTU: alu_op = `ALU_SLTU;
            endcase
        end
        `OP_STORE: begin
            fetch_reg(rs1,opr1);
            fetch_reg(rs2,val);
            opr2=imm_S;
            case (funct3)
                `FUNCT3_SB: wlen = 2'b00;
                `FUNCT3_SH: wlen = 2'b01;
                `FUNCT3_SW: wlen = 2'b11;
            endcase
        end
        `OP_OP: begin
            fetch_reg(rs1,opr1);
            fetch_reg(rs2,opr2);
            //reg_idx = rs2;
            //reg_re = 1;
            //opr2 = reg_in;
            case (funct3)
                `FUNCT3_ADD_SUB: alu_op = (funct7[5]) ? `ALU_SUB : `ALU_ADD;
                `FUNCT3_SLL: alu_op = `ALU_SLL;
                `FUNCT3_SRL_SRA: alu_op = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                `FUNCT3_XOR: alu_op = `ALU_XOR;
                `FUNCT3_SLT: alu_op = `ALU_SLT;
                `FUNCT3_SLTU: alu_op = `ALU_SLTU;
                `FUNCT3_OR: alu_op = `ALU_OR;
                `FUNCT3_AND: alu_op = `ALU_AND;
                default: $display("ERROR:ID OP_OP");
            endcase
        end
        `OP_MISC_MEM: opr2=0;
        default: $display("ID: unknown op:%b",op);
    endcase
    $display("ID: op:%b f3:%b f7:%b rd:%d rs1:%d rs2:%d opr1:%d opr2:%d",op,funct3,funct7,rd,rs1,rs2,opr1,opr2);
    #1;
    down_syn = 1;
end

always @(negedge up_syn) begin
    up_ack <= #1 0;
end
always @(posedge down_ack) begin
    down_syn <= #1 0;
end
endmodule
