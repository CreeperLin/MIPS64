`ifdef SIM
`include "def.v"
`endif
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
    output reg c_rack, c_wack,
    
    input[`C_DATA_L] m_din,
    output reg[`C_DATA_L] m_dout,
    output reg[`M_ADDR_L] m_raddr,
    output reg[`M_ADDR_L] m_waddr,
    output reg[`RW_E_L] m_re, m_we,
    output reg[`RW_LEN_L] m_rlen,
    output reg[`RW_LEN_L] m_wlen,
    input m_rack, m_wack
);
localparam REF_B = 2;
localparam VALID_B = 1;
localparam DIRTY_B = 0;
localparam SET_B = `LOG2(SET);
localparam OFS_B = WORD_B + 2;
localparam TAG_B = `K_M_ADDR_L - IDX_B - OFS_B;
localparam FLG_B = 3;// ref valid dirty
reg[FLG_B+TAG_B-1:0] info[SET-1:0][(1<<IDX_B)-1:0];
//reg[8-1:0] data[SET-1:0][IDX_B-1:0][OFS_B-1:0];
reg[32-1:0] data[SET-1:0][(1<<IDX_B)-1:0][(1<<WORD_B)-1:0];

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
wire[SET-1:0] r_dirty;
wire[SET-1:0] r_avail;
wire[SET-1:0] r_replace;

wire[FLG_B+TAG_B-1:0] w_key[SET-1:0];
wire[SET-1:0] w_match;
wire[SET-1:0] w_dirty;
wire[SET-1:0] w_avail;
wire[SET-1:0] w_replace;

wire signed[SET_B:0] set_sel[(1<<SET)-1:0];

localparam STATE_B =            6;
localparam STATE_IDLE =         0;
localparam STATE_FE =           1;
localparam STATE_FE_WAIT =      2;
localparam STATE_FL =           4;      
localparam STATE_FL_WAIT =      8;
localparam STATE_R_WAIT =       16;
localparam STATE_W_WAIT =       32;
reg[STATE_B-1:0] state;

genvar i;
generate
    for (i=0;i<(1<<SET);i=i+1) begin
        assign set_sel[i] = `LOG2(i); 
    end
    for (i=0;i<SET;i=i+1) begin
        assign r_key[i] = info[i][r_idx];
        assign r_match[i] = (r_key[i][TAG_B+VALID_B] == 1) && (r_key[i][TAG_B-1:0] == r_tag);
        assign r_avail[i] = r_key[i][TAG_B+VALID_B] == 0;
        assign r_dirty[i] = r_key[i][TAG_B+DIRTY_B];
        assign r_replace[i] = r_key[i][TAG_B+REF_B] == 0;
        assign w_key[i] = info[i][w_idx];
        assign w_match[i] = (w_key[i][TAG_B+VALID_B] == 1) && (w_key[i][TAG_B-1:0] == w_tag);
        assign w_avail[i] = w_key[i][TAG_B+VALID_B] == 0;
        assign w_dirty[i] = w_key[i][TAG_B+DIRTY_B];
        assign w_replace[i] = w_key[i][TAG_B+REF_B] == 0;
    end
endgenerate

//assign m_raddr = c_raddr;
//assign m_waddr = c_waddr;
//assign m_rlen = c_rlen;
//assign m_wlen = c_wlen;

task w_data;
input[SET-1:0] t_set;
input[IDX_B-1:0] t_idx;
input[WORD_B-1:0] t_wofs;
input[TAG_B-1:0] t_tag;
input[`C_DATA_L] t_din;
begin
    data[t_set][t_idx][t_wofs] <= t_din;
    info[t_set][t_idx] <= {3'b111,t_tag};
    $display("CACHE:%0d Write s:%0d i:%0d o:%0d t:%x d:%x",ID,t_set,t_idx,t_wofs,t_tag,t_din);
end
endtask

reg[SET-1:0] fe_set;
reg[TAG_B-1:0] fe_tag;
reg[IDX_B-1:0] fe_idx;
reg unsigned[WORD_B-1:0] fe_ofs;

task fetch_line;
input[SET-1:0] t_set;
input[TAG_B-1:0] t_tag;
input[IDX_B-1:0] t_idx;
//reg unsigned[WORD_B-1:0] t_ofs;
begin
    fe_set <= t_set;
    fe_tag <= t_tag;
    fe_idx <= t_idx;
    fe_ofs <= 0;
    state <= STATE_FE;
end
endtask

reg[SET-1:0] fl_set;
reg[TAG_B-1:0] fl_tag;
reg[IDX_B-1:0] fl_idx;
reg unsigned[WORD_B-1:0] fl_ofs;

task flush_line;
input[SET-1:0] t_set;
input[TAG_B-1:0] t_tag;
input[IDX_B-1:0] t_idx;
//reg unsigned[WORD_B:0] t_ofs;
begin
    fl_set <= t_set;
    fl_tag <= t_tag;
    fl_idx <= t_idx;
    fl_ofs <= 0;
    state <= STATE_FL;
end
endtask

always @(posedge c_re) begin
    #1;
    $display("CACHE:%0d Read t:%b i:%b w:%b k:%b m:%b",ID,r_tag,r_idx,r_word,r_key[1],r_match);
    if (r_match > 0) begin
        c_dout <= data[set_sel[r_match]][r_idx][r_word];
        //info[set_sel[r_match]][r_idx][TAG_B+REF_B] = 1;
        $display("CACHE:%0d ReadHit %b %x %x",ID,r_match,c_raddr,c_dout);
        //$stop;
        c_rack <= 1;
    end else begin
        m_raddr <= c_raddr;
        m_rlen <= c_rlen;
        m_re <= 1;
        state <= STATE_R_WAIT;
    end
end

always @(posedge c_we) begin
    //write through
    m_dout <= c_din;
    m_waddr <= c_waddr;
    m_wlen <= c_wlen;
    state <= STATE_W_WAIT;
    m_we <= 1;
    if (w_match>0) begin
        data[set_sel[w_match]][w_idx][w_word] <= c_din;
        info[set_sel[w_match]][w_idx][TAG_B+DIRTY_B] <= 1;
        $display("CACHE:%0d WriteHit %b %x %d",ID,w_match,c_waddr,c_din);
    end else begin
        $display("CACHE:%0d WriteMiss %x %d",ID,c_waddr,c_din);
       
    end
end

always @(state) begin
    case (state)
        STATE_IDLE: begin $display("CACHE:%0d Idle",ID);
        end
        STATE_FE: begin
            m_raddr <= {fe_tag,fe_idx,fe_ofs[WORD_B-1:0],2'b00}; 
            m_rlen <= 2'b11;
            //#1;
            state <= STATE_FE_WAIT;
            m_re <= 1;
        end
        STATE_FE_WAIT: begin

        end
        STATE_FL: begin
            m_waddr <= {fl_tag,fl_idx,fl_ofs[WORD_B-1:0],2'b00}; 
            m_dout <= data[fl_set][fl_idx][fl_ofs];
            m_wlen <= 2'b11;
            state <= STATE_FL_WAIT;
            m_we <= 1;
        end
        STATE_FL_WAIT: begin
            
        end
        STATE_R_WAIT: begin
        end
        STATE_W_WAIT: begin
        end
        default: $display("CACHE:ERROR unknown state");
    endcase
end

always @(posedge m_rack) begin
    m_re <= 0;
    case (state) 
        STATE_FE_WAIT: begin
            data[fe_set][fe_idx][fe_ofs] <= m_din;
            $display("CACHE:%0d Fetched a:%x s:%0d i:%0d o:%0d d:%x",ID,m_raddr,fe_set,fe_idx,fe_ofs,m_din);
            if (fe_ofs==(1<<WORD_B)-1) begin
                fe_ofs <= 0;
                info[fe_set][fe_idx] <= {3'b110,fe_tag};
                $display("CACHE:%0d FetchDone s:%0d i:%x t:%x",ID,fe_set,fe_idx,fe_tag);
                c_rack <= c_re ? 1 : 0;
                state <= STATE_IDLE;
            end else begin
                fe_ofs <= fe_ofs + 1;
                state <= STATE_FE;
            end
        end
        STATE_R_WAIT: begin
            c_dout <= m_din;
            $display("CACHE: avail:%b",r_avail);
            if (r_avail>0) begin
                fetch_line(set_sel[r_avail],r_tag,r_idx); 
                $display("CACHE:%0d ReadMissCreate s:%b %x",ID,r_avail,c_raddr);
            end else begin
                if (info[set_sel[r_replace]][r_idx][TAG_B+DIRTY_B] == 1) begin
                    flush_line(set_sel[r_replace],
                        info[set_sel[r_replace]][r_idx][TAG_B-1:0],
                        r_idx);
                end
                fetch_line(set_sel[r_replace],r_tag,r_idx); 
                $display("CACHE:%0d ReadMissReplace %b %x",ID,r_replace,c_raddr);
            end
        end
        default: $display("CACHE:%0d ERROR unknown rack",ID);
    endcase
end

always @(posedge m_wack) begin
    m_we <= 0;
    case (state)
        STATE_FL_WAIT: begin
            $display("CACHE:%0d Flushed a:%x s:%0d i:%0d o:%0d d:%x",ID,m_waddr,fl_set,fl_idx,fl_ofs,m_dout);
            if (fl_ofs==(1<<WORD_B)-1) begin
                fl_ofs <= 0;
                $display("CACHE:%0d FlushDone s:%0d i:%x t:%x",ID,fl_set,fl_idx,fl_tag);
                state <= STATE_IDLE;
            end else begin
                fl_ofs <= fl_ofs + 1;
                state <= STATE_FL;
            end
        end
        STATE_W_WAIT: begin
            c_wack <= 1;
        end
        default: $display("CACHE:%0d ERROR unknown wack %d",ID,state);
    endcase
end

integer j,k,l;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m_re <= 0;
        m_we <= 0;
        c_dout <= 0;
        m_dout <= 0;
        c_rack <= 0;
        c_wack <= 0;
        m_waddr <= 0;
        m_raddr <= 0;
        m_wlen <= 0;
        m_rlen <= 0;
        state <= STATE_IDLE;
        for (j=0;j<SET;j=j+1) begin
            for (k=0;k<(1<<IDX_B);k=k+1) begin
                for (l=0;l<(1<<WORD_B);l=l+1) begin
                    data[j][k][l] = 0;
                end
                info[j][k] = 32'h0000ffff;
            end
        end
    end else begin

    end
end

always @(negedge c_re) begin
    c_rack <= 0;
end

always @(negedge c_we) begin
    c_wack <= 0;
end

integer m;
initial begin
    for (m=0;m<(1<<SET);m=m+1) begin
        $display("setsel %b %d %d",m,set_sel[m],`LOG2(m));
    end
end
endmodule

