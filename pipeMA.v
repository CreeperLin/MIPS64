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

    input re, we,
    input[1:0] rlen, wlen,
    input[4:0] rd,
    input[MADDR_L-1:0] ex_ans,
    input[DATA_L-1:0] ex_din,
    input[DATA_L-1:0] mem_in,
    output reg[DATA_L-1:0] mem_out,
    output reg[MADDR_L-1:0] m_raddr,m_waddr,
    output reg co_re, co_we,
    output reg[1:0] co_rlen, co_wlen,
    input ex_wb_e,
    output wb_e,
    output[4:0] wb_idx,
    output reg[DATA_L-1:0] wb_out
);
assign wb_e = re | ex_wb_e;
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
    if (re) begin
        co_rlen = rlen;
        m_raddr = ex_ans;
        co_re = 1;
        wb_out = mem_in;
        co_re = 0; 
    end else if (we) begin
        co_wlen = wlen;
        m_waddr = ex_ans;
        co_we = 1;
        mem_out = ex_din;
        co_we = 0;
    end else begin
        wb_out = ex_ans;
    end
    $display("MA: m_raddr:%x mem_in:%d m_waddr:%x mem_out:%d",m_raddr,mem_in,m_waddr,mem_out);
    down_syn = 1;
end
always @(negedge up_syn) begin
    up_ack <= #1 0;
end
always @(posedge down_ack) begin
    down_syn <= #1 0;
end
endmodule
