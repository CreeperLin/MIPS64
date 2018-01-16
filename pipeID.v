/*decoder*/
`include "def.v"
`include "riscv_const.v"
`include "alu_opcode.v"
module pipeID
#(
    parameter REG_SZ = 32,
    parameter ALUOP_L = 5
)
(
    input clk, rst,
    input buf_avail,
    output reg buf_re,
    output reg buf_we,
    input buf_rack, buf_wack,

    input[31:0] inst,
    input[31:0] pc_in,
    output[31:0] pc_out,
    output reg reg_re,
    input reg_rack,
    output reg[4:0] reg_idx,
    input[REG_SZ-1:0] reg_in,
    //input[REG_SZ-1:0] pc_in,

    output reg[ALUOP_L-1:0] alu_op,
    output reg alu_c,
    output[4:0] rd,
    output reg[4:0] rs1_out,rs2_out,
    output signed[REG_SZ-1:0] opr1,opr2,val,
    //output reg signed[31:0] imm,
    output jp_e, br_e, wb_e,
    //output reg wb_e,
    output reg[1:0] rw_e,
    output reg[1:0] rw_len,
    input[4:0] MA_fwd_idx,
    input[31:0] MA_fwd_val,
    input[4:0] EX_fwd_idx,
    input[31:0] EX_fwd_val,
    input MA_ack,EX_ack
);

localparam STATE_B      = 3;
localparam STATE_IDLE   = 0;
localparam STATE_F0     = 1;
localparam STATE_F1     = 2;
localparam STATE_F2     = 3;
localparam STATE_WAITMA = 4;
reg[STATE_B-1:0] state,nstate;

reg[31:0] reg_fwd[31:0];
reg[4:0] rd_lock;
reg[31:0] reg_lock;
reg[31:0] reg_lock_pend;
reg signed[REG_SZ-1:0] t_opr[2:0];
assign opr1 = t_opr[0];
assign opr2 = t_opr[1];
assign val = t_opr[2];
wire[6:0] op;
wire[4:0] rs1, rs2;
wire[6:0] funct7;
wire[2:0] funct3;
wire signed[31:0] imm_I, imm_S, imm_B, imm_U, imm_J;
assign imm_I = {{21{inst[31]}},inst[30:20]};
assign imm_S = {{21{inst[31]}},inst[30:25],inst[11:7]};
assign imm_B = {{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0};
assign imm_U = {inst[31:12],12'b0};
assign imm_J = {{12{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0};
assign op = inst[6:0];
assign rd = inst[11:7];
assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign funct7 = inst[31:25];
assign funct3 = inst[14:12];
assign pc_out = pc_in;

assign wb_e = !(op==`OP_BRANCH || op==`OP_STORE || op==`OP_SYSTEM); 
assign jp_e = (op==`OP_JAL) || (op==`OP_JALR);
assign br_e = (op==`OP_BRANCH);

reg[5:0] wait_idx;
reg[2:0] wait_opr;

task fetch_reg;
input[4:0] idx;
input[2:0] oidx;

begin
    case (idx)
        5'b0: begin
            t_opr[oidx] = 0;
            state = STATE_IDLE;
        end
        default: begin
            if (reg_lock[idx]) begin
                case (oidx)
                0: nstate <= STATE_F0;
                1: nstate <= STATE_F1;
                2: nstate <= STATE_F2;
                endcase
                wait_opr = oidx;
                wait_idx = idx;
                state = STATE_WAITMA;
                $display("ID:DATA STALL %d", idx);
            end else begin
                t_opr[oidx] = reg_fwd[idx];
                state = STATE_IDLE;
            end
        end
    endcase
end
endtask

reg wait_end;

integer i;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        t_opr[0] <= 0;
        t_opr[1] <= 0;
        t_opr[2] <= 0;
        buf_re <= 0;
        buf_we <=0;
        rw_e <= 0;
        rw_len <= 0;
        alu_c <= 0;
        state <= STATE_IDLE;
        nstate <= STATE_IDLE;
        wait_end <= 0;
        reg_re <= 0;
        rd_lock <= 0;
        for (i=0;i<32;i=i+1) begin
            reg_fwd[i] <= 0;
            reg_lock[i] <= 0;
            reg_lock_pend[i] <= 0;
        end
    end else begin

    end
end

task lock_reg;
    input[4:0] t_idx;
    if (t_idx) begin
        rd_lock <= t_idx;
        $display("ID:REG %d locked",t_idx);
    end
endtask

always @(posedge EX_ack) begin
    $display("ID:EXFWD %d %d %d",EX_fwd_idx,EX_fwd_val,reg_lock[EX_fwd_idx]);
    reg_fwd[EX_fwd_idx] <= EX_fwd_val;
    if (EX_fwd_idx!=0 && reg_lock[EX_fwd_idx]) begin
        reg_lock[EX_fwd_idx] <= reg_lock_pend[EX_fwd_idx] ? 1 : 0;
        reg_lock_pend[EX_fwd_idx] <= 0; 
        $display("ID:REG %d unlocked %d",EX_fwd_idx,reg_lock[EX_fwd_idx]);
        if (wait_idx==EX_fwd_idx) begin
            t_opr[wait_opr] <= EX_fwd_val;
            $display("ID:Wait end %d %d %d",wait_opr,t_opr[wait_opr],state);
            wait_idx <= 6'b111111;
            wait_opr <= 3'b111;
            state <= nstate;
            wait_end <= 1;
        end
    end
end
always @(posedge MA_ack) begin
    reg_fwd[MA_fwd_idx] <= MA_fwd_val;
    $display("ID:MAFWD %d %d %d",MA_fwd_idx,MA_fwd_val,reg_lock[MA_fwd_idx]);
    if (MA_fwd_idx!=0 && reg_lock[MA_fwd_idx]) begin
        reg_lock[MA_fwd_idx] <= reg_lock_pend[MA_fwd_idx] ? 1 : 0;
        reg_lock_pend[MA_fwd_idx] <= 0; 
        $display("ID:REG %d unlocked %d",MA_fwd_idx,reg_lock[MA_fwd_idx]);
        if (wait_idx==MA_fwd_idx) begin
            t_opr[wait_opr] <= MA_fwd_val;
            $display("ID:Wait end %d %d %d",wait_opr,t_opr[wait_opr],state);
            wait_idx <= 6'b111111;
            wait_opr <= 3'b111;
            state <= nstate;
            wait_end <= 1;
        end
    end
end

always @(posedge buf_avail) begin
    if (state == STATE_IDLE)
        buf_re <= 1;
    else begin 
        $display("ID:Busy %d",state);
    end
end

always @(posedge buf_rack) begin
    buf_re <= 0;
    rw_e = 0;
    alu_c = 1'b0;
    rs1_out = 0;
    rs2_out = 0;
    if (state!=STATE_IDLE) begin
        $display("ID:ASSERT failed");
        $stop;
    end
    case (op)
        `OP_LUI:begin
            alu_op = `ALU_PASS;
            t_opr[0] = imm_U;
            t_opr[1] = 0;
            lock_reg(rd);
        end
        `OP_AUIPC: begin
            alu_op = `ALU_ADD;
            t_opr[0] = pc_in;
            t_opr[1] = imm_U;
            lock_reg(rd);
        end
        `OP_JAL: begin
            alu_op = `ALU_ADD;
            t_opr[0] = imm_J;
            t_opr[1] = pc_in;
            t_opr[2] = 32'h4;
            lock_reg(rd);
        end
        `OP_JALR: begin
            alu_op = `ALU_ADD;
            rs1_out = rs1;
            t_opr[1] = imm_I;
            t_opr[2] = 32'h4;
            fetch_reg(rs1,0);
            lock_reg(rd);
        end
        `OP_OP_IMM: begin
            rs1_out = rs1;
            t_opr[1]=imm_I;
            case (funct3)
                `FUNCT3_ADDI: alu_op = `ALU_ADD;
                `FUNCT3_SLLI: alu_op = `ALU_SLL;
                `FUNCT3_SRLI_SRAI: alu_op = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                `FUNCT3_XORI: alu_op = `ALU_XOR;
                `FUNCT3_SLTI: alu_op = `ALU_SLT;
                `FUNCT3_SLTIU: alu_op = `ALU_SLTU;
                `FUNCT3_ORI: alu_op = `ALU_OR;
                `FUNCT3_ANDI: alu_op = `ALU_AND;
                default: $display("ID:ERROR OP_OP");
            endcase
            fetch_reg(rs1,0);
            lock_reg(rd);
        end
        `OP_LOAD: begin
            rs1_out = rs1;
            t_opr[1]=imm_I;
            alu_op = `ALU_ADD;    
            case (funct3)
                `FUNCT3_LB: begin
                    rw_len = 2'b00;
                    rw_e = 2'b10;
                end
                `FUNCT3_LBU: begin
                    rw_len = 2'b00;
                    rw_e = 2'b11;
                end
                `FUNCT3_LH: begin
                    rw_len = 2'b01;
                    rw_e = 2'b10;
                end
                `FUNCT3_LHU: begin
                    rw_len = 2'b01;
                    rw_e = 2'b11;
                end
                `FUNCT3_LW: begin
                    rw_len = 2'b11;
                    rw_e = 2'b10;
                end
                default: $display("ID:ERROR LOAD");
            endcase
            fetch_reg(rs1,0);
            lock_reg(rd);
        end
        `OP_BRANCH: begin
            rs1_out = rs1;
            rs2_out = rs2;
            t_opr[2]=imm_B;
            case (funct3)
                `FUNCT3_BEQ:
                    alu_op = `ALU_SEQ;
                `FUNCT3_BNE: begin
                    alu_op = `ALU_SEQ;
                    alu_c = 1'b1;
                end
                `FUNCT3_BLT: alu_op = `ALU_SLT;
                `FUNCT3_BLTU: alu_op = `ALU_SLTU;
                `FUNCT3_BGE: begin
                    alu_op = `ALU_SLT;
                    alu_c = 1;
                end
                `FUNCT3_BGEU: begin
                    alu_op = `ALU_SLTU;
                    alu_c = 1;
                end
                default: $display("ID:ERROR BRANCH");
            endcase
            fetch_reg(rs1,0);
            if (state == STATE_IDLE)
                fetch_reg(rs2,1);
        end
        `OP_STORE: begin
            rs1_out = rs1;
            t_opr[1]=imm_S;
            alu_op = `ALU_ADD;
            rw_e = 2'b01;
            case (funct3)
                `FUNCT3_SB: rw_len = 2'b00;
                `FUNCT3_SH: rw_len = 2'b01;
                `FUNCT3_SW: rw_len = 2'b11;
                default: $display("ID:ERROR STORE");
            endcase
            fetch_reg(rs1,0);
            if(state == STATE_IDLE)
                fetch_reg(rs2,2); 
        end
        `OP_OP: begin
            rs1_out = rs1;
            rs2_out = rs2;
            case (funct3)
                `FUNCT3_ADD_SUB: alu_op = (funct7[5]) ? `ALU_SUB : `ALU_ADD;
                `FUNCT3_SLL: alu_op = `ALU_SLL;
                `FUNCT3_SRL_SRA: alu_op = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                `FUNCT3_XOR: alu_op = `ALU_XOR;
                `FUNCT3_SLT: alu_op = `ALU_SLT;
                `FUNCT3_SLTU: alu_op = `ALU_SLTU;
                `FUNCT3_OR: alu_op = `ALU_OR;
                `FUNCT3_AND: alu_op = `ALU_AND;
                default: $display("ID:ERROR OP_OP");
            endcase
            fetch_reg(rs1,0);
            if (state==STATE_IDLE)
                fetch_reg(rs2,1);
            lock_reg(rd);
        end
        `OP_MISC_MEM: begin
            alu_op <= `ALU_PASS;
            $display("ID:MISCMEM N/A");
        end
        `OP_SYSTEM: begin
            alu_op <= `ALU_PASS;
            $display("ID:syscall N/A");
        end
        default: $display("ID:ERROR unknown op:%b",op);
    endcase
    $display("ID:%x op:%b f3:%b f7:%b rd:%d rs1:%d rs2:%d opr1:%d opr2:%d val:%d alu_op:%d",pc_in,op,funct3,funct7,rd,rs1,rs2,t_opr[0],t_opr[1],t_opr[2],alu_op);
    if (reg_re==0 && state==STATE_IDLE) begin
        buf_we <= 1;
    end
end

always @(posedge wait_end) begin
    wait_end <= 0;
    case (state)
        STATE_IDLE: begin $display("ID:Idle");
        end
        STATE_F0: begin
            case (op)
                `OP_OP, `OP_BRANCH: begin
                    fetch_reg(rs2,1);
                    buf_we <= (state==STATE_IDLE) ? 1 : 0;
                end
                `OP_STORE: begin
                    fetch_reg(rs2,2);
                    //state = reg_re ? STATE_F2 : STATE_IDLE;
                    buf_we <= (state==STATE_IDLE) ? 1 : 0;
                end
                default: begin 
                    state <= STATE_IDLE;
                    buf_we <= 1;
                end
            endcase
        end
        STATE_F1, STATE_F2: begin
            state <= STATE_IDLE;
            buf_we <= 1;
        end
        default: $display("ID:ERROR rack");
    endcase
end

always @(posedge reg_rack) begin
    reg_re <= 0;
    case (state)
        STATE_IDLE: begin $display("ID:Idle");
        end
        STATE_F0: begin
            t_opr[0] <= reg_in;
            case (op)
                `OP_OP, `OP_BRANCH: begin
                    fetch_reg(rs2,1);
                    buf_we <= (state==STATE_IDLE) ? 1 : 0;
                end
                `OP_STORE: begin
                    fetch_reg(rs2,2);
                    //state = reg_re ? STATE_F2 : STATE_IDLE;
                    buf_we <= (state==STATE_IDLE) ? 1 : 0;
                end
                default: begin 
                    state <= STATE_IDLE;
                    buf_we <= 1;
                end
            endcase
        end
        STATE_F1: begin
            t_opr[1] <= reg_in;
            state <= STATE_IDLE;
            buf_we <= 1;
        end
        STATE_F2: begin
            t_opr[2] <= reg_in;
            state <= STATE_IDLE;
            buf_we <= 1;
        end
        default: $display("ID:ERROR rack");
    endcase
end

always @(posedge buf_wack) begin
    if (rd_lock) begin
        reg_lock_pend[rd_lock] <= reg_lock[rd_lock] ? 1 : 0;
        reg_lock[rd_lock] <= 1;
        rd_lock <= 0;
    end
    buf_we <= 0;
    buf_re <= buf_avail ? 1 : 0;
end

endmodule
