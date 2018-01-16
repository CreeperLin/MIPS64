`ifdef SIM
`include "alu.v"
`endif
module pipeEX
#(
    parameter REG_SZ = 32
)
(
    input clk, rst,
    input buf_avail,
    output reg buf_re,
    output reg buf_we,
    input buf_rack, buf_wack,
    
    input[31:0] pc_in,
    input[`ALUOP_L] op_in,
    input c_in,
    input[4:0] rd,rs1,rs2,
    input signed[REG_SZ-1:0] opr1_in, opr2_in, val_in,
    output signed[REG_SZ-1:0] ans,
    
    //control
    output signed[REG_SZ-1:0] dout,
    input[1:0] rw_e_in,
    input[1:0] rw_len_in,
    output[1:0] rw_e_out,
    output[1:0] rw_len_out,
    input wb_e_in,
    output wb_e_out,
    output[4:0] wb_idx_out,
    input jp_e_in,
    input br_e_in,
    output reg jp_e_out,
    output reg[REG_SZ-1:0] jp_pc,
    input jp_ack,
    //output jp_e_out,
    //output [REG_SZ-1:0] jp_pc
    output[10-1:0] bp_tag_out,
    output reg bp_t_out,
    output reg bp_we,
    input bp_wack,
    input[4:0] MA_fwd_idx,
    input[31:0] MA_fwd_val,
    input MA_ack,
    output[4:0] EX_fwd_idx,
    output[31:0] EX_fwd_val
);
wire[2:0] st;
assign dout = val_in;
assign rw_e_out = rw_e_in;
assign rw_len_out = rw_len_in;
assign wb_e_out = wb_e_in;
assign wb_idx_out = rd;

assign EX_fwd_idx = (wb_e_in&&!rw_e_in) ? rd : 0;
assign EX_fwd_val = ans;
assign bp_tag_out = pc_in[10-1:0];

reg[REG_SZ-1:0] alu_opr1,alu_opr2;
reg[`ALUOP_L] alu_op;
reg alu_c, alu_run;
wire alu_ack;
c_alu alu1(clk,rst,alu_run,alu_opr1,alu_opr2,alu_c,alu_op,ans,st,alu_ack);

localparam STATE_B          = 3;
localparam STATE_IDLE       = 0;
localparam STATE_OPR_CAL    = 1;
localparam STATE_JADDR_CAL  = 2;
localparam STATE_BADDR_CAL  = 4;
reg[STATE_B-1:0] state;

task run_alu;
input [`ALUOP_L] t_op;
input [REG_SZ-1:0] t_opr1, t_opr2;
input t_c;
begin
    alu_run = 0;
    alu_opr1 <= t_opr1;
    alu_opr2 <= t_opr2;
    alu_c <= t_c;
    alu_op <= t_op;
    alu_run <= 1;
end
endtask

reg[4:0] MA_fi;
reg[31:0] MA_fv;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        jp_e_out <= 0;
        jp_pc <= 0;
        alu_op <= 0;
        alu_opr1 <= 0;
        alu_opr2 <= 0;
        alu_run <= 0;
        alu_c <= 0;
        buf_re <= 0;
        buf_we <= 0;
        bp_we <= 0;
        bp_t_out <= 0;
        state <= STATE_IDLE;
        MA_fi <= 0;
        MA_fv <= 0;
    end else begin

    end
end
reg[REG_SZ-1:0] opr1,opr2;
always @(posedge buf_avail) begin
    buf_re <= 1;
end

always @(posedge MA_ack) begin
    MA_fi <= MA_fwd_idx;
    MA_fv <= MA_fwd_val;
    $display("EX:MA fwd %d %d",MA_fi,MA_fv);
end

always @(posedge buf_rack) begin
    buf_re <= 0;
    case (rs1)
        5'b0: opr1 = opr1_in;
        MA_fi: begin
            opr1 = MA_fv;
            $display("EX:fwdMA %d %d",rs1,opr1);
        end
        default: opr1 = opr1_in;
    endcase
    case (rs2)
        5'b0: opr2 = opr2_in;
        MA_fi: begin
            opr2 = MA_fv;
            $display("EX:fwdMA %d %d",rs2,opr2);
        end
        default: opr2 = opr2_in;
    endcase
    MA_fi <= 0;
    $display("EX:%x alu_op:%d rd:%d opr1:%d opr2:%d val:%d c:%d ans:%d jp_e: %d jp_pc:%x",pc_in,op_in,rd,opr1,opr2,val_in,c_in,ans,jp_e_out,jp_pc);
    run_alu(op_in,opr1,opr2,c_in);
    state <= STATE_OPR_CAL;
end

always @(posedge alu_ack) begin
    alu_run <= 0;
    $display("ALU:%x op:%d A:%d B:%d c:%d Y:%d",pc_in,alu_op,alu_opr1,alu_opr2,alu_c,ans);
    case (state)
        STATE_IDLE: begin $display("EX:Idle");
        end
        STATE_OPR_CAL: begin
            if (br_e_in) begin
                bp_t_out <= ans[0];
                if (ans[0]) begin
                    run_alu(`ALU_ADD,val_in,pc_in,1'b0);
                    state <= STATE_BADDR_CAL;
                end else begin
                    jp_pc <= 0;
                    jp_e_out <= 1;
                    bp_we <= 1;
                    buf_we <= 1;
                end
            end else if (jp_e_in) begin
                jp_pc <= ans;
                jp_e_out <= 1;
                run_alu(`ALU_ADD,pc_in,val_in,1'b0);
                state <= STATE_JADDR_CAL;
            end else begin
                buf_we <= 1;        
            end
        end
        STATE_BADDR_CAL: begin
            jp_pc <= ans;
            jp_e_out <= 1;
            bp_we <= 1;
            buf_we <= 1;
        end
        STATE_JADDR_CAL: begin
            buf_we <= 1;
        end
        default: $display("EX:ERROR unknown state");
    endcase
end

always @(posedge buf_wack) begin
    buf_we <= 0;
    buf_re <= buf_avail ? 1 : 0;
end

always @(posedge jp_ack) begin
    jp_e_out <= 0;
end

endmodule
