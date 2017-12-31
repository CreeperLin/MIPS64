/*IF*/
`include "b_predictor.v"
`define PC_ENTRY 32'h00000000
`define PC_MAIN 32'h00001000
module pipeIF
#(
    parameter INST_L = 32,
    parameter PC_L = 32,
    parameter MADDR_L = 32
)
(
    input clk, rst,
    input up_syn,
    output reg up_ack,
    output reg down_syn,
    input down_ack,

    //output purge_e,
    input jp_e,
    input[PC_L-1:0] pc_in,
    input[INST_L-1:0] datain,
    output reg[MADDR_L-1:0] addr,
    output reg re,
    output [1:0] r_len,
    output reg[INST_L-1:0] inst,
    //output [PC_L-1:0] nxpc 
    output reg[PC_L-1:0] pc_out
    //output reg[PC_L-1:0] nxpc_out
);
localparam BP_TAG_L = 10;
localparam BP_LHLEN = 8;
localparam BP_GHLEN = 12;
wire bp_t_out;
reg bp_we,bp_t_in;
reg[BP_TAG_L-1:0] bp_tag_q;
reg[BP_TAG_L-1:0] bp_tag_in;
b_predictor#(.TAG_LEN(BP_TAG_L),.LOCAL_HLEN(BP_LHLEN),.GLOBAL_HLEN(BP_GHLEN))
bp(clk,rst,bp_we,bp_tag_in,bp_t_in,bp_tag_q,bp_t_out);

reg[PC_L-1:0] pc;
reg[PC_L-1:0] j_pc;
reg j;

reg[PC_L-1:0] nxpc;
//assign nxpc = (jp_e==1'b1) ? pc_in : pc + 4;
//assign nxpc = pc + 4;

assign r_len = 3;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        //pc <= 0;
        pc <= `PC_ENTRY;
        nxpc <= `PC_ENTRY;
        pc_out <= 0;
        up_ack <= 0;
        down_syn <=0;
        inst <= 0;
        addr <= 0;
        re <= 0;
    end else begin

    end
end

//wire[PC_L-1:0] inst_no;
//assign inst_no = (pc-`PC_MAIN)/4;

always @(posedge up_syn) begin
    pc = nxpc;
    addr = pc[MADDR_L-1:0];
    re = 1;
    #5;
    //inst[31:0] = {datain[7:0],datain[15:8],datain[23:16],datain[31:24]};
    inst = datain;
    re = 0;
    //pc <= nxpc;
    pc_out = nxpc;
    nxpc = nxpc + 4;
    $display("IF: read pc: %x jp_e: %x, inst: %X nxpc: %x",pc,jp_e,inst,nxpc);

    up_ack = 1;
    if (inst!=32'b0) begin
        down_syn = 1;
    end else begin
        $stop;
    end
end

always @(posedge jp_e) begin
    //j_pc = pc_in;
    nxpc = pc_in;
    $display("IF:Goto %x",nxpc);
end

always @(negedge up_syn) begin
    up_ack = #1 0;
end

always @(posedge down_ack) begin
    down_syn = #1 0;
end

endmodule
