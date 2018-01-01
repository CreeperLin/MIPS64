`include "def.v"
module pipeMA
#(
    parameter MADDR_L = 32,
    parameter DATA_L = 32
)
(
    input clk, rst,
    input buf_avail,
    output reg buf_re,
    output reg buf_we,
    input buf_ack,

    input[1:0] rw_e,
    input[1:0] rw_len,
    input[`M_ADDR_L] ex_ans,
    input[`C_DATA_L] ex_din,
    input[`C_DATA_L] mem_in,
    output reg[`C_DATA_L] mem_out,
    output reg[`M_ADDR_L] m_raddr,m_waddr,
    output reg co_re, co_we,
    output reg[1:0] co_rlen, co_wlen,
    input ex_wb_e,
    output wb_e,
    input[4:0] ex_wb_idx,
    output[4:0] wb_idx,
    output reg[`C_DATA_L] wb_out,
    output[4:0] MA_fwd_idx,
    output[31:0] MA_fwd_val
);
assign wb_e = ex_wb_e;
assign wb_idx = ex_wb_idx;

assign MA_fwd_idx = ((rw_e==2'b11)||(rw_e==2'b10)) ? ex_wb_idx : 0;
assign MA_fwd_val = wb_out;
//assign co_re = re;
//assign co_we = we;
//assign co_rlen = rlen;
//assign co_wlen = wlen;
//assign wb_out = mem_in;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        buf_re <= 0;
        buf_we <=0;
        co_we <= 0;
        co_re <= 0;
        co_rlen <= 0;
        co_wlen <= 0;
        //co_wlen <= 0;
        //co_rlen <= 0;
    end else begin

    end
end
always @(posedge buf_avail) begin
    buf_re = 1;
    buf_re = #1 0;
    #5;
    case (rw_e)
    2'b10: begin
        co_rlen = rw_len;
        m_raddr = ex_ans;
        co_re = 1;
        co_re = #5 0; 
        case (rw_len)
            2'b00: wb_out = {{25{mem_in[7]}}, mem_in[6:0]};
            2'b01: wb_out = {{17{mem_in[15]}}, mem_in[14:0]};
            2'b11: wb_out = mem_in;
            default: $display("MA:Error");
        endcase
        $display("MA:Read m_raddr:%x mem_in:%d",m_raddr,mem_in);
    end
    2'b11: begin
        co_rlen = rw_len;
        m_raddr = ex_ans;
        co_re = 1;
        co_re = #5 0;
        wb_out = mem_in;
        //case (rw_len)
            //2'b00: wb_out = {24'b0, mem_in[7:0]};
            //2'b01: wb_out = {16'b0, mem_in[15:0]};
            //2'b11: wb_out = mem_in;
            //default: $display("MA:Error");
        //endcase
        $display("MA:Read Unsigned m_raddr:%x mem_in:%d wb_out:%d",m_raddr,mem_in,wb_out);
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
    default: $display("MA:ERROR");
    endcase
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
