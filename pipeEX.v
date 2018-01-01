`include "alu.v"
module pipeEX
#(
    parameter REG_SZ = 32
)
(
    input clk, rst,
    input buf_avail,
    output reg buf_re,
    output reg buf_we,
    input buf_ack,
    
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
    //output jp_e_out,
    //output [REG_SZ-1:0] jp_pc
    output[10-1:0] bp_tag_out,
    output reg bp_t_out,
    output reg bp_we,
    input[4:0] MA_fwd_idx,
    input[31:0] MA_fwd_val,
    output[4:0] EX_fwd_idx,
    output[31:0] EX_fwd_val
);
wire[2:0] st;
assign dout = val_in;
assign rw_e_out = rw_e_in;
assign rw_len_out = rw_len_in;
assign wb_e_out = wb_e_in;
assign wb_idx_out = rd;

assign EX_fwd_idx = wb_e_in ? rd : 0;
assign EX_fwd_val = ans;
//assign jp_e_out = (br_e_in && ans[0]) || jp_e_in;
//assign jp_pc = ans;
assign bp_tag_out = pc_in[10-1:0];
//assign bp_t_out = ans[0];

reg[REG_SZ-1:0] alu_opr1,alu_opr2;
reg[`ALUOP_L] alu_op;
reg alu_c, alu_run;
alu alu1(clk,rst,alu_run,alu_opr1,alu_opr2,alu_c,alu_op,ans,st);

task run_alu;
input [`ALUOP_L] t_op;
input [REG_SZ-1:0] t_opr1, t_opr2;
input t_c;
//output t_ans;
begin
    alu_run = 0;
    alu_opr1 = t_opr1;
    alu_opr2 = t_opr2;
    alu_c = t_c;
    alu_op = t_op;
    alu_run = 1;
    #3;
    alu_run = 0;
    $display("ALU:op:%d A:%d B:%d c:%d Y:%d",t_op,t_opr1,t_opr2,t_c,ans);
end
endtask

always @(posedge clk or posedge rst) begin
    if (rst) begin
        jp_e_out <= 0;
        jp_pc <= 0;
        alu_op <= 0;
        alu_opr1 <= 0;
        alu_opr2 <= 0;
        alu_c <= 0;
        buf_re <= 0;
        buf_we <= 0;
        bp_we <= 0;
        bp_t_out <= 0;
    end else begin

    end
end
reg[REG_SZ-1:0] opr1,opr2;
always @(posedge buf_avail) begin
    buf_re = 1;
    buf_re = #1 0;
    opr1 = 0;
    opr2 = 0;
    case (rs1)
        5'b0: opr1 = opr1_in;
        MA_fwd_idx: begin
            opr1 = MA_fwd_val;
            $display("EX:fwdMA %d %d",rs1,opr1);
        end
        default: opr1 = opr1_in;
    endcase
    case (rs2)
        5'b0: opr2 = opr2_in;
        MA_fwd_idx: begin
            opr2 = MA_fwd_val;
            $display("EX:fwdMA %d %d",rs2,opr2);
        end
        default: opr2 = opr2_in;
    endcase
    run_alu(op_in,opr1,opr2,c_in);
    if (br_e_in) begin
        bp_t_out = ans[0];
        if (ans[0]) begin
            run_alu(`ALU_ADD,val_in,pc_in,1'b0);
            jp_pc = ans;
        end else begin
            jp_pc = 0;
        end
        jp_e_out = 1;
        jp_e_out = #1 0;
        bp_we = 1;
        bp_we = #1 0;
    end else if (jp_e_in) begin
        jp_pc = ans;
        jp_e_out = 1;
        jp_e_out = #1 0;
        run_alu(`ALU_ADD,pc_in,val_in,1'b0);
    end
    $display("EX: alu_op:%d rd:%d opr1:%d opr2:%d c:%d ans:%d jp_e: %d jp_pc:%x",op_in,rd,opr1_in,opr2_in,c_in,ans,jp_e_out,jp_pc);
    buf_we = 1;
    buf_we = #1 0;
end
//always @(negedge buf_avail) begin
    //buf_re <= #1 0;
//end
//always @(posedge buf_ack) begin
    //buf_we <= #1 0;
//end
endmodule
