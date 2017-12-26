`include "alu.v"
module pipeEX
#(
    parameter REG_SZ = 32
)
(
    input clk, rst,
    input up_syn,
    output reg up_ack,
    output reg down_syn,
    input down_ack,
    
    input[31:0] pc_in,
    input[`ALUOP_L] op_in,
    input c_in,
    input[4:0] rd,
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
    input jp_e_in,
    input br_e_in,
    output reg jp_e_out,
    output reg[REG_SZ-1:0] jp_pc
    //output jp_e_out,
    //output [REG_SZ-1:0] jp_pc
);
wire[2:0] st;
assign dout = val_in;
assign rw_e_out = rw_e_in;
assign rw_len_out = rw_len_in;
assign wb_e_out = wb_e_in;
//assign jp_e_out = (br_e_in && ans[0]) || jp_e_in;
//assign jp_pc = ans;

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
        up_ack <= 0;
        down_syn <=0;
    end else begin

    end
end
always @(posedge up_syn) begin
    #1;
    up_ack = 1;
    run_alu(op_in,opr1_in,opr2_in,c_in);
    if (br_e_in && ans[0]) begin
        run_alu(`ALU_ADD,val_in,pc_in,1'b0);
        jp_pc = ans;
        jp_e_out = 1;
        jp_e_out = #1 0;
    end else if (jp_e_in) begin
        jp_pc = ans;
        jp_e_out = 1;
        jp_e_out = #1 0;
        run_alu(`ALU_ADD,pc_in,val_in,1'b0);
    end
    $display("EX: alu_op:%d rd:%d opr1:%d opr2:%d c:%d ans:%d jp_e: %d jp_pc:%x",op_in,rd,opr1_in,opr2_in,c_in,ans,jp_e_out,jp_pc);
    down_syn = 1;
end
always @(negedge up_syn) begin
    up_ack <= #1 0;
end
always @(posedge down_ack) begin
    down_syn <= #1 0;
end
endmodule
