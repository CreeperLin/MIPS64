/*Memory Management Unit*/
`include "def.v"
`ifdef SIM
`include "buffer.v"
`endif
module mmu_uart
#(
    parameter M_RPORT = 1,
    parameter M_WPORT = 1,
    parameter C_RPORT = 2,
    parameter C_WPORT = 1
)
(
    input clk, rst,
    input[M_RPORT*`C_DATA_L] m_din,
    output reg[M_WPORT*`C_DATA_L] m_dout,
    output reg[M_RPORT*`M_ADDR_L] m_raddr,
    output reg[M_WPORT*`M_ADDR_L] m_waddr,
    output reg[M_RPORT*`RW_E_L] m_re,
    output reg[M_WPORT*`RW_E_L] m_we,
    output reg[M_RPORT*`RW_LEN_L] m_rlen,
    output reg[M_WPORT*`RW_LEN_L] m_wlen,
    input[M_RPORT-1:0] m_rack,
    input[M_WPORT-1:0] m_wack,

    input[C_WPORT*`C_DATA_L] c_din,
    output[C_RPORT*`C_DATA_L] c_dout,
    input[C_RPORT*`M_ADDR_L] c_raddr,
    input[C_WPORT*`M_ADDR_L] c_waddr,
    input[C_RPORT*`RW_E_L] c_re,
    input[C_WPORT*`RW_E_L] c_we,
    input[C_RPORT*`RW_LEN_L] c_rlen, 
    input[C_WPORT*`RW_LEN_L] c_wlen,
    output reg[C_RPORT-1:0] c_rack,
    output reg[C_WPORT-1:0] c_wack
);
localparam STATE_B      = 3;
localparam STATE_IDLE   = 0;
localparam STATE_R_WAIT = 1;
localparam STATE_W_WAIT = 2;

localparam C_RPORT_B = `LOG2(C_RPORT);
localparam C_WPORT_B = 1;
wire[C_RPORT_B-1:0] rport_sel[(1<<C_RPORT)-1:0];
genvar u;
generate
    for (u=0;u<(1<<C_RPORT);u=u+1) begin
        assign rport_sel[u] = `LOG2(u);
    end
endgenerate

localparam RBUF_L = C_RPORT_B + 2 + `K_M_ADDR_L;
localparam WBUF_L = C_WPORT_B + 2 + `K_M_ADDR_L + `K_C_DATA_L;
reg rbuf_we,rbuf_qwe,rbuf_re,wbuf_we,wbuf_re;
wire rbuf_wack,rbuf_rack,rb_a,rb_f,
    wbuf_wack,wbuf_rack,wb_a,wb_f;
//wire[RBUF_L-1:0] rbuf_din;
reg[RBUF_L-1:0] rbuf_din;
reg[RBUF_L-1:0] rbuf_qdin;
wire[RBUF_L-1:0] rbuf_dout;
//wire[C_RPORT_B-1:0] rb_port;
//wire[`M_ADDR_L] rb_raddr;
//wire[`RW_LEN_L] rb_rlen;
//assign rb_port = rbuf_dout[`K_M_ADDR_L+2];
//assign rb_rlen = rbuf_dout[`K_M_ADDR_L+1:`K_M_ADDR_L];
//assign rb_raddr = rbuf_dout[`M_ADDR_L];
reg[C_RPORT_B-1:0] rb_port;
reg[`M_ADDR_L] rb_raddr;
reg[`RW_LEN_L] rb_rlen;
wire[WBUF_L-1:0] wbuf_din;
wire[WBUF_L-1:0] wbuf_dout;
wire[C_WPORT_B-1:0] wb_port;
wire[`M_ADDR_L] wb_waddr;
wire[`C_DATA_L] wb_data;
wire[`RW_LEN_L] wb_wlen;
assign wb_port = wbuf_dout[2+`K_M_ADDR_L+`K_C_DATA_L];
assign wb_wlen = wbuf_dout[65:64];
assign wb_waddr = wbuf_dout[`K_C_DATA_L+`K_M_ADDR_L-1:`K_C_DATA_L];
assign wb_data = wbuf_dout[`C_DATA_L];
//assign rbuf_din = {rport_sel[c_re],c_rlen_seg[rport_sel[c_re]],c_raddr_seg[rport_sel[c_re]]};
assign wbuf_din = {1'b0,c_wlen,c_waddr,c_din};
buffer#(.BUF_ID(5),.ADDR_L(5),.DATA_L(RBUF_L)) rbuf(
    clk,rst,rbuf_re,rbuf_we,rbuf_din,rbuf_dout,rbuf_rack,rbuf_wack,rb_a,rb_f
);
buffer#(.BUF_ID(6),.ADDR_L(5),.DATA_L(WBUF_L)) wbuf(
    clk,rst,wbuf_re,wbuf_we,wbuf_din,wbuf_dout,wbuf_rack,wbuf_wack,wb_a,wb_f
);
reg r_busy;

always @(posedge rbuf_wack) begin
    rbuf_we <= 0;
end

always @(negedge rbuf_we) begin
    if (rbuf_qwe) begin
        rbuf_qwe <= 0;
        rbuf_din <= rbuf_qdin;
        rbuf_we <= 1;
        $display("MMU:Queued:%b",rbuf_din);
    end
end

always @(posedge wbuf_wack) begin
    wbuf_we <= 0;
end
always @(posedge wb_a) begin
    wbuf_re <= 1;
end
always @(posedge rb_a) begin
    if (!r_busy)
        rbuf_re <= 1;
end

reg[`C_DATA_L] c_r_buf[C_RPORT-1:0];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        r_busy <= 0;
        rbuf_re <= 0;
        rbuf_din <= 0;
        rbuf_qdin <= 0;
        rbuf_qwe <= 0;
        rbuf_we <= 0;
        wbuf_we <= 0;
        wbuf_re <= 0;
        //empty_r_buf;
        c_r_buf[0] <= 0;
        c_r_buf[1] <= 0;
        c_wack <= 0;
        c_rack <= 0;
        m_raddr <= 0;
        m_waddr <= 0;
        m_re <= 0;
        m_we <= 0;
        m_rlen <= 0;
        m_wlen <= 0;
        m_dout <= 0;
        rb_port <= 0;
        rb_rlen <= 0;
        rb_raddr <= 0;
    end else begin
    end
end
//reg unsigned[3:0] i,j,k,l;

wire[`M_ADDR_L] c_raddr_seg[C_RPORT-1:0];
wire[`RW_LEN_L] c_rlen_seg[C_RPORT-1:0];
genvar t;
generate
    for(t=0;t<C_RPORT;t=t+1) begin
       assign c_raddr_seg[t] = c_raddr[(t+1)*`K_M_ADDR_L-1:t*`K_M_ADDR_L];
       assign c_rlen_seg[t] = c_rlen[(t+1)*2-1:t*2];
       assign c_dout[(t+1)*`K_C_DATA_L-1:t*`K_C_DATA_L] = c_r_buf[t];
    end
endgenerate

always @(posedge rbuf_rack) begin
    r_busy <= 1;
    rb_port = rbuf_dout[`K_M_ADDR_L+2];
    rb_rlen = rbuf_dout[`K_M_ADDR_L+1:`K_M_ADDR_L];
    rb_raddr = rbuf_dout[`M_ADDR_L];
    $display("MMU:Read p:%b l:%d a:%x",rb_port,rb_rlen,rb_raddr);
    rbuf_re <= 0;
    c_r_buf[rb_port] <= 0;
    m_raddr <= rb_raddr;
    m_rlen <= rb_rlen;
    m_re <= 1;
end

always @(posedge m_rack) begin
    c_r_buf[rb_port] <= m_din;
    m_re <= 0;
    $display("MMU:Read Done p:%d c_raddr:%x len:%d data:%x",rb_port,rb_raddr,rb_rlen+1,c_r_buf[rb_port]);
    c_rack[rb_port] <= 1;
    r_busy <= 0;
    rbuf_re <= rb_a ? 1 : 0;
end

always @(posedge wbuf_rack) begin
    m_dout <= wb_data;
    m_waddr <= wb_waddr;
    m_wlen <= wb_wlen;
    wbuf_re <= 0;
    m_we <= 1;
end

always @(posedge m_wack) begin
    m_we <= 0;
    $display("MMU:Write Done c_waddr:%x len:%d data:%d",wb_waddr,wb_wlen+1,wb_data);    
    c_wack <= 1;
end

always @(posedge c_re[0]) begin
    $display("MMU:RBUF re:%b p:%b din:%b",c_re,rport_sel[c_re],rbuf_din); 
    rbuf_qdin = {1'b0,c_rlen_seg[0],c_raddr_seg[0]};
    if (rbuf_we) begin
        rbuf_qwe <= 1;
        $display("MMU:ERROR BUSY %d",0);
    end else begin
        rbuf_din <= rbuf_qdin;
        rbuf_we <= 1;
    end
end

always @(posedge c_re[1]) begin
    $display("MMU:RBUF re:%b p:%b din:%b",c_re,rport_sel[c_re],rbuf_din); 
    rbuf_qdin = {1'b1,c_rlen_seg[1],c_raddr_seg[1]};
    if (rbuf_we) begin
        rbuf_qwe <= 1;
        $display("MMU:ERROR BUSY %d",1);
    end else begin
        rbuf_din <= rbuf_qdin;
        rbuf_we <= 1;
    end
end

always @(negedge c_re[0]) begin
    c_rack[0] <= 0;
end

always @(negedge c_re[1]) begin
    c_rack[1] <= 0;
end
always @(posedge c_we) begin
    $display("MMU:WBUF din:%b",wbuf_din);
    wbuf_we <= 1;
end

always @(negedge c_we) begin
    c_wack <= 0;
end

endmodule
