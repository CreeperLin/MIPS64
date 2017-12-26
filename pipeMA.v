`include "def.v"
module pipeMA
#(
    parameter MADDR_L = 32,
    parameter DATA_L = 32
)
(
    input clk, rst,
    input up_syn,
    output reg up_ack,
    output reg down_syn,
    input down_ack,

    input[1:0] rw_e,
    input[1:0] rw_len,
    input[4:0] rd,
    input[`M_ADDR_L] ex_ans,
    input[`C_DATA_L] ex_din,
    input[`C_DATA_L] mem_in,
    output reg[`C_DATA_L] mem_out,
    output reg[`M_ADDR_L] m_raddr,m_waddr,
    output reg co_re, co_we,
    output reg[1:0] co_rlen, co_wlen,
    input ex_wb_e,
    output wb_e,
    output[4:0] wb_idx,
    output reg[`C_DATA_L] wb_out
);
assign wb_e = ex_wb_e;
assign wb_idx = rd;
//assign co_re = re;
//assign co_we = we;
//assign co_rlen = rlen;
//assign co_wlen = wlen;
//assign wb_out = mem_in;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        up_ack <= 0;
        down_syn <=0;
        co_we <= 0;
        co_re <= 0;
        co_rlen <= 0;
        co_wlen <= 0;
        //co_wlen <= 0;
        //co_rlen <= 0;
    end else begin

    end
end
always @(posedge up_syn) begin
    #1;
    up_ack = 1;
    #5;
    case (rw_e)
    2'b10: begin
        co_rlen = rw_len;
        m_raddr = ex_ans;
        co_re = 1;
        co_re = #5 0; 
        wb_out = mem_in;
        $display("MA:Read m_raddr:%x mem_in:%d",m_raddr,mem_in);
    end
    2'b11: begin
        co_rlen = rw_len;
        m_raddr = ex_ans;
        co_re = 1;
        co_re = #5 0;
        wb_out = {mem_in[31:16],16'b0};
        $display("MA:ReadUpper m_raddr:%x mem_in:%d wb_out:%d",m_raddr,mem_in,wb_out);
    end
    2'b01: begin
        co_wlen = rw_len;
        m_waddr = ex_ans;
        co_we = 1;
        mem_out = ex_din;
        co_we = #5 0;
        $display("MA:Write m_waddr:%x mem_out:%d",m_waddr,mem_out);
    end
    2'b00: begin
        wb_out = ex_ans;
        $display("MA:None");
    end
    default: $display("MA:Error");
    endcase
    down_syn = 1;
end
always @(negedge up_syn) begin
    up_ack <= #1 0;
end
always @(posedge down_ack) begin
    down_syn <= #1 0;
end
endmodule
