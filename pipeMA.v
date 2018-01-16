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
    input buf_rack, buf_wack,
    //output reg stg_ack,

    input[1:0] rw_e,
    input[1:0] rw_len,
    input[`M_ADDR_L] ex_ans,
    input[`C_DATA_L] ex_din,
    input[`C_DATA_L] mem_in,
    output reg[`C_DATA_L] mem_out,
    output reg[`M_ADDR_L] m_raddr,m_waddr,
    output reg co_re, co_we,
    output reg[1:0] co_rlen, co_wlen,
    input co_rack, co_wack,
    input ex_wb_e,
    output wb_e,
    input[4:0] ex_wb_idx,
    output[4:0] wb_idx,
    output reg[`C_DATA_L] wb_out,
    output[4:0] MA_fwd_idx,
    output[31:0] MA_fwd_val
);

localparam STATE_B      = 3;
localparam STATE_IDLE   = 0;
localparam STATE_R      = 1;
localparam STATE_RU     = 2;
localparam STATE_W      = 4;
reg[STATE_B-1:0] state;

assign wb_e = ex_wb_e;
assign wb_idx = ex_wb_idx;

assign MA_fwd_idx = ((state==STATE_IDLE)&&((rw_e==2'b11)||(rw_e==2'b10))) ? ex_wb_idx : 0;
assign MA_fwd_val = wb_out;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        buf_re <= 0;
        buf_we <= 0;
        co_we <= 0;
        co_re <= 0;
        co_rlen <= 0;
        co_wlen <= 0;
        state <= STATE_IDLE;
    end else begin

    end
end

always @(posedge buf_avail) begin
    if (state==STATE_IDLE)
        buf_re <= 1;
end

always @(posedge buf_rack) begin
    buf_re <= 0;
    case (rw_e)
    2'b10: begin
        co_rlen <= rw_len;
        m_raddr <= ex_ans;
        co_re <= 1;
        state <= STATE_R;
    end
    2'b11: begin
        co_rlen <= rw_len;
        m_raddr <= ex_ans;
        co_re <= 1;
        state <= STATE_RU;       
    end
    2'b01: begin
        co_wlen <= rw_len;
        m_waddr <= ex_ans;
        mem_out <= ex_din;
        co_we <= 1;
        state <= STATE_W;
    end
    2'b00: begin
        wb_out <= ex_ans;
        state <= STATE_IDLE;
        buf_we <= 1;
        $display("MA:None");
    end
    default: $display("MA:ERROR");
    endcase
end

always @(posedge buf_wack) begin
    $display("MA:Fwd %d %d",MA_fwd_idx,MA_fwd_val);
    buf_we <= 0;
    buf_re <= buf_avail ? 1 : 0;
end

always @(posedge co_rack) begin
    case (state)
        STATE_R: begin
            case (rw_len)
                2'b00: wb_out = {{25{mem_in[7]}}, mem_in[6:0]};
                2'b01: wb_out = {{17{mem_in[15]}}, mem_in[14:0]};
                2'b11: wb_out = mem_in;
                default: $display("MA:Error");
            endcase
            $display("MA:Read m_raddr:%x mem_in:%d",m_raddr,mem_in);
        end
        STATE_RU: begin
        wb_out = mem_in;
        $display("MA:Read Unsigned m_raddr:%x mem_in:%d wb_out:%d",m_raddr,mem_in,wb_out);
        end
        default: $display("MA:ERROR rack");
    endcase
    co_re <= 0;
    state <= STATE_IDLE;
    buf_we <= 1;
end
always @(posedge co_wack) begin
    co_we <= 0;
    case (state)
        STATE_W: begin
            $display("MA:Write m_waddr:%x mem_out:%d",m_waddr,mem_out);
        end
        default: $display("MA:ERROR wack");
    endcase
    state <= STATE_IDLE;
    buf_we <= 1;
end
endmodule
