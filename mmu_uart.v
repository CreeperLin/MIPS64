/*Memory Management Unit*/
`include "def.v"
`include "buffer.v"
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
reg rbuf_we,rbuf_re,wbuf_we,wbuf_re;
wire rbuf_wack,rbuf_rack,rb_a,rb_f,
    wbuf_wack,wbuf_rack,wb_a,wb_f;
wire[RBUF_L-1:0] rbuf_din;
//reg[RBUF_L-1:0] rbuf_din;
wire[RBUF_L-1:0] rbuf_dout;
wire[C_RPORT_B-1:0] rb_port;
wire[`M_ADDR_L] rb_raddr;
wire[`RW_LEN_L] rb_rlen;
assign rb_port = rbuf_dout[`K_M_ADDR_L+2];
assign rb_rlen = rbuf_dout[`K_M_ADDR_L+1:`K_M_ADDR_L];
assign rb_raddr = rbuf_dout[`M_ADDR_L];
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
assign rbuf_din = {rport_sel[c_re],c_rlen_seg[rport_sel[c_re]],c_raddr_seg[rport_sel[c_re]]};
assign wbuf_din = {1'b0,c_wlen,c_waddr,c_din};
buffer#(.BUF_ID(5),.ADDR_L(5),.DATA_L(RBUF_L)) rbuf(
    clk,rst,rbuf_re,rbuf_we,rbuf_din,rbuf_dout,rbuf_rack,rbuf_wack,rb_a,rb_f
);
buffer#(.BUF_ID(5),.ADDR_L(5),.DATA_L(WBUF_L)) wbuf(
    clk,rst,wbuf_re,wbuf_we,wbuf_din,wbuf_dout,wbuf_rack,wbuf_wack,wb_a,wb_f
);

always @(posedge rbuf_wack) begin
    rbuf_we = 0;
end
always @(posedge wbuf_wack) begin
    wbuf_we = 0;
end
always @(posedge wb_a) begin
    wbuf_re = 1;
end
always @(posedge rb_a) begin
    rbuf_re = 1;
end

//reg[`M_DATA_L] r_buf[3:0];
reg[`C_DATA_L] c_r_buf[C_RPORT-1:0];
//reg[`M_DATA_L] w_buf[3:0];
//task empty_r_buf;
    //begin
        //r_buf[0] = 0;
        //r_buf[1] = 0;
        //r_buf[2] = 0;
        //r_buf[3] = 0;
    //end
//endtask

always @(posedge clk or posedge rst) begin
    if (rst) begin
        rbuf_re = 0;
        rbuf_we = 0;
        wbuf_we = 0;
        wbuf_re = 0;
        //empty_r_buf;
        c_r_buf[0] = 0;
        c_r_buf[1] = 0;
        c_wack = 0;
        c_rack = 0;
        m_raddr = 0;
        m_waddr = 0;
        m_re = 0;
        m_we = 0;
        m_rlen = 0;
        m_wlen = 0;
        m_dout = 0;
        //rbuf_din = 0;
    end else begin
        rbuf_re = (rb_a&(!rbuf_re)) ? 1 : 0;
        wbuf_re = (wb_a&(!wbuf_re)) ? 1 : 0;
    end
end
reg unsigned[3:0] i,j,k,l;

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

//reg[1:0] t_rlen, t_wlen;
always @(posedge rbuf_rack) begin
    //$display("MMU:RBUF p:%b l:%d a:%x",rb_port,rb_rlen,rb_raddr);
    rbuf_re = 0;
    c_r_buf[rb_port] = 0;
    //empty_r_buf;
    m_raddr = rb_raddr;
    m_rlen = rb_rlen;
    //i = 0;    
    m_re = 1;
end

always @(posedge m_rack) begin
    //r_buf[i] = m_din;
    c_r_buf[rb_port] = m_din;
    m_re = 0;
    //if (i==rb_rlen) begin
    //c_r_buf[rb_port] = {r_buf[3],r_buf[2],r_buf[1],r_buf[0]};
    $display("MMU:ReadPort:%d c_raddr:%x len:%d data:%x",rb_port,rb_raddr,rb_rlen+1,c_r_buf[rb_port]);
    c_rack[rb_port] = 1;
    //end else begin
        //i = i + 1;
        //m_raddr = m_raddr + 1;
        //m_re = 1; 
    //end
end

always @(posedge wbuf_rack) begin
    //w_buf[3] = wb_data[31:24];
    //w_buf[2] = wb_data[23:16];
    //w_buf[1] = wb_data[15:8];
    //w_buf[0] = wb_data[7:0];
    m_dout = wb_data;
    m_waddr = wb_waddr;
    m_wlen = wb_wlen;
    wbuf_re = 0;
    //j = 0;
    //m_dout = w_buf[j];
    m_we = 1;
end

always @(posedge m_wack) begin
    m_we = 0;
    //if (j==wb_wlen) begin
    $display("MMU:Write c_waddr:%x len:%d data:%d",wb_waddr,wb_wlen+1,wb_data);    
    c_wack = 1;
    //end else begin
        //j = j + 1;
        //m_dout = w_buf[j];
        //m_waddr = m_waddr + 1;
        //m_we = 1;
    //end
end

always @(posedge c_re[0]) begin
    //$display("MMU:RBUF re:%b p:%b din:%b",c_re,rport_sel[c_re],rbuf_din); 
    //rbuf_din = {1'b0,c_rlen_seg[0],c_raddr_seg[0]};
    if (rbuf_we) begin
        $display("MMU:ERROR BUSY %d",k);
    end else begin
        rbuf_we = 1;
    end
end

always @(posedge c_re[1]) begin
    //$display("MMU:RBUF re:%b p:%b din:%b",c_re,rport_sel[c_re],rbuf_din); 
    //rbuf_din = {1'b1,c_rlen_seg[1],c_raddr_seg[1]};
    if (rbuf_we) begin
        $display("MMU:ERROR BUSY %d",k);
    end else begin
        rbuf_we = 1;
    end
end

always @(negedge c_re[0]) begin
    c_rack[0] = 0;
end

always @(negedge c_re[1]) begin
    c_rack[1] = 0;
end

//always @(posedge c_re) begin
//always @(c_re) begin
    //$display("MMU:RBUF re:%b din:%b",c_re,rbuf_din); 
    //rbuf_we = 1;
    //for (k=0;k<C_RPORT;k=k+1) begin
        //if(c_re[k]) begin
            //if (rbuf_we) begin
                //$display("MMU:ERROR BUSY %d",k);
            //end else begin
                //rbuf_we = 1;
            //end
        //end else begin
            //c_rack[k] = 0;
        //end
    //end
    //$display("MMU:%b %x %x",c_re,c_rlen,c_raddr);
//end
//always @(c_we) begin
always @(posedge c_we) begin
    //$display("MMU:WBUF din:%b",wbuf_din);
    wbuf_we = 1;
end

always @(negedge c_we) begin
    c_wack = 0;
end

endmodule
