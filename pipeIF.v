/*IF*/
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
    
    input jp_e,
    input[PC_L-1:0] pc_in,
    input[INST_L-1:0] datain,
    output reg[MADDR_L-1:0] addr,
    output reg re,
    output reg[1:0] r_len,
    output reg[INST_L-1:0] inst
);
reg[PC_L-1:0] pc;
wire[PC_L-1:0] nxpc;
//assign nxpc = (jp_e==1'b1) ? pc_in : pc + 4;
assign nxpc = 0;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pc <= 0;
        up_ack <= 0;
        down_syn <=0;
        inst <= 0;
        addr <= 0;
        re <= 0;
        r_len <= 0;
    end else begin

    end
end
always @(posedge up_syn) begin
    addr <= pc[MADDR_L-1:0];
    r_len <= 3;
    re <= 1;
    #5;
    inst[31:0] = {datain[7:0],datain[15:8],datain[23:16],datain[31:24]};
    re = 0;
    $display("IF: read pc: %x jp_e: %x, inst: %X",pc,jp_e,inst);
    //pc <= nxpc;
    pc = (jp_e==1'b1) ? pc_in : pc + 4;
    up_ack = 1;
    if (inst!=32'b0) begin
        down_syn = 1;
    end
end

always @(negedge up_syn) begin
    up_ack = #1 0;
end

always @(posedge down_ack) begin
    down_syn = #1 0;
end

endmodule
