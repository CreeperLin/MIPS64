`include "def.v"
module cache
#(
    parameter ID = 0,
    parameter WORD_B = 3, //word bit
    parameter IDX_B = 5, //idx bit
    parameter SET = 2
)
(
    input clk, rst,
    input[`C_DATA_L] c_din,
    output reg[`C_DATA_L] c_dout,
    input[`M_ADDR_L] c_raddr,
    input[`M_ADDR_L] c_waddr,
    input[`RW_E_L] c_re, c_we,
    input[`RW_LEN_L] c_rlen, c_wlen,
    
    input[`C_DATA_L] m_din,
    output reg[`C_DATA_L] m_dout,
    output[`M_ADDR_L] m_raddr,
    output[`M_ADDR_L] m_waddr,
    output reg[`RW_E_L] m_re, m_we,
    output[`RW_LEN_L] m_rlen, m_wlen
);
localparam REF_B = 2;
localparam VALID_B = 1;
localparam DIRTY_B = 0;

localparam OFS_B = WORD_B + 2;
localparam TAG_B = 32 - IDX_B - OFS_B;
localparam FLG_B = 3;// ref valid dirty
reg[FLG_B+TAG_B-1:0] info[SET-1:0][IDX_B-1:0];
//reg[8-1:0] data[SET-1:0][IDX_B-1:0][OFS_B-1:0];
reg[32-1:0] data[SET-1:0][IDX_B-1:0][WORD_B-1:0];

wire[TAG_B-1:0] r_tag;
wire[IDX_B-1:0] r_idx;
wire[OFS_B-1:0] r_ofs;
wire[WORD_B-1:0] r_word;
wire[TAG_B-1:0] w_tag;
wire[IDX_B-1:0] w_idx;
wire[OFS_B-1:0] w_ofs;
wire[WORD_B-1:0] w_word;
assign r_tag = c_raddr[`K_M_ADDR_L-1:`K_M_ADDR_L-TAG_B];
assign r_idx = c_raddr[`K_M_ADDR_L-TAG_B-1:OFS_B];
assign r_ofs = c_raddr[OFS_B-1:0];
assign r_word = c_raddr[OFS_B-1:2];
assign w_tag = c_waddr[`K_M_ADDR_L-1:`K_M_ADDR_L-TAG_B];
assign w_idx = c_waddr[`K_M_ADDR_L-TAG_B-1:OFS_B];
assign w_ofs = c_waddr[OFS_B-1:0];
assign w_word = c_waddr[OFS_B-1:2];

wire[FLG_B+TAG_B-1:0] r_key[SET-1:0];
wire[32-1:0] r_data;
wire[SET-1:0] r_match;

wire[FLG_B+TAG_B-1:0] w_key[SET-1:0];
wire[SET-1:0] w_match;
wire[SET-1:0] w_dirty;
wire[SET-1:0] w_avail;
wire[SET-1:0] w_replace;

wire[(2**SET)-1:0] set_sel;

genvar i;
generate
    for (i=0;i<(1<<SET);i=i+1) begin
        assign set_sel[i] = `LOG2(i); 
    end
    for (i=0;i<SET;i=i+1) begin
        assign r_key[i] = info[i][r_idx];
        assign r_match[i] = (r_key[i][TAG_B+VALID_B] == 1) && (r_key[i][TAG_B-1:0] == r_tag);
        assign w_key[i] = info[i][w_idx];
        assign w_match[i] = (w_key[i][TAG_B+VALID_B] == 1) && (w_key[i][TAG_B-1:0] == w_tag);
        assign w_avail[i] = w_key[i][TAG_B+VALID_B] == 0;
        assign w_dirty[i] = w_key[i][TAG_B+DIRTY_B];
        assign w_replace[i] = w_key[i][TAG_B+REF_B] == 0;
    end
endgenerate

assign m_raddr = c_raddr;
assign m_waddr = c_waddr;
assign m_rlen = c_rlen;
assign m_wlen = c_wlen;

always @(c_re) begin
    if (r_match==-1) begin
        m_re = 1;
        m_re = #5 0;
        c_dout = m_din;
        $display("CACHE:%0d ReadMiss %x from MEM: %d",ID,c_raddr,c_dout);
    end else begin
        c_dout = data[set_sel[r_match]][r_idx][r_word];
        $display("CACHE:%0d ReadHit %x %d",c_raddr,c_dout);
    end
end

always @(c_we) begin
    if (w_match==-1) begin
        if (w_avail==-1) begin
            data[set_sel[w_replace]][w_idx][w_word] = c_din;
            info[set_sel[w_replace]][w_idx] = {1'b1,1'b1,w_tag};
            $display("CACHE:%0d WriteMissReplace %x %d set:%d",ID,c_waddr,c_din,set_sel[w_avail]);
        end else begin
            data[set_sel[w_avail]][w_idx][w_word] = c_din;
            info[set_sel[w_avail]][w_idx] = {1'b1,1'b1,w_tag};
            $display("CACHE:%0d WriteMissCreate %x %d set:%d",ID,c_waddr,c_din,set_sel[w_avail]);
        end
    end else begin
        data[set_sel[w_match]][w_idx][w_word] = c_din;
        info[set_sel[w_match]][w_idx][TAG_B+DIRTY_B] = 1;
        $display("CACHE:%0d WriteHit %x %d set:%d",ID,c_waddr,c_din,set_sel[w_match]);
    end
    //write through
    m_dout = c_din;
    m_we = 1;
    m_we = #5 0;
end

integer j,k,l;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m_re = 0;
        m_we = 0;
        c_dout = 0;
        m_dout = 0;
        for (j=0;j<(1<<SET);j=j+1) begin
            for (k=0;k<(1<<IDX_B);k=k+1) begin
                for (l=0;l<(1<<WORD_B);l=l+1) begin
                    data[j][k][l] = 0;
                end
                info[j][k] = 0;
            end
        end
    end else begin

    end
end

endmodule

