/*Memory Management Unit*/
`include "def.v"
module mmu
#(
    parameter M_RPORT = 1,
    parameter M_WPORT = 1,
    parameter C_RPORT = 2,
    parameter C_WPORT = 1
)
(
    input clk, rst,
    input[M_RPORT*`M_DATA_L] m_din,
    output reg[M_WPORT*`M_DATA_L] m_dout,
    output reg[M_RPORT*`M_ADDR_L] m_raddr,
    output reg[M_WPORT*`M_ADDR_L] m_waddr,
    output reg[M_RPORT*`RW_E_L] m_re,
    output reg[M_WPORT*`RW_E_L] m_we,

    input[C_WPORT*`C_DATA_L] c_din,
    output reg[C_RPORT*`C_DATA_L] c_dout,
    input[C_RPORT*`M_ADDR_L] c_raddr,
    input[C_WPORT*`M_ADDR_L] c_waddr,
    input[C_RPORT*`RW_E_L] c_re,
    input[C_WPORT*`RW_E_L] c_we,
    input[C_RPORT*`RW_LEN_L] c_rlen, 
    input[C_WPORT*`RW_LEN_L] c_wlen
);
reg[`M_DATA_L] r_buf[3:0];
reg[`C_DATA_L] c_r_buf[C_RPORT-1:0];
reg[`M_DATA_L] w_buf[3:0];
task empty_r_buf;
    //input  pt;
    begin
        r_buf[0] <= 0;
        r_buf[1] <= 0;
        r_buf[2] <= 0;
        r_buf[3] <= 0;
    end
endtask

always @(posedge clk or posedge rst) begin
    if (rst) begin
        empty_r_buf;
        c_r_buf[0] <= 0;
        c_r_buf[1] <= 0;
    end else begin
    end
end
reg[2:0] i,j,k,l;

wire[`M_ADDR_L] c_raddr_seg[C_RPORT-1:0];
wire[`RW_LEN_L] c_rlen_seg[C_RPORT-1:0];
genvar t;
generate
    for(t=0;t<C_RPORT;t=t+1) begin
       assign c_raddr_seg[t] = c_raddr[(t+1)*`K_M_ADDR_L-1:t*`K_M_ADDR_L];
       assign c_rlen_seg[t] = c_rlen[(t+1)*2-1:t*2];
    end
endgenerate

//always @(posedge c_re) begin
always @(c_re) begin
    //$display("MMU:%b %x %x",c_re,c_rlen,c_raddr);
    c_dout = 0;
    for (k=0;k<C_RPORT;k=k+1) begin
        c_r_buf[k] = 0;
        if (c_re[k]) begin
            empty_r_buf;
            m_raddr = c_raddr_seg[k];
            for (i=0;i<=c_rlen_seg[k];i=i+1) begin
                m_re = 1;
                #1;
                r_buf[i] = m_din;
                //$display("MMU: buf%d:%x",i,r_buf[i]);
                m_re = 0;
                m_raddr = m_raddr + 1;
            end
            //c_r_buf[k] = {r_buf[0],r_buf[1],r_buf[2],r_buf[3]};
            c_r_buf[k] = {r_buf[3],r_buf[2],r_buf[1],r_buf[0]};
            $display("MMU:ReadPort:%d c_raddr:%x len:%d data:%x",k,c_raddr_seg[k],c_rlen_seg[k]+1,c_r_buf[k]);
        end
    end
    c_dout = {c_r_buf[1],c_r_buf[0]};
    //$display("MMU:Read %x",c_dout);
end
//always @(c_we) begin
always @(posedge c_we) begin
    m_waddr = c_waddr;
    w_buf[3] = c_din[31:24];
    w_buf[2] = c_din[23:16];
    w_buf[1] = c_din[15:8];
    w_buf[0] = c_din[7:0];
    for (j=0;j<=c_wlen;j=j+1) begin
        m_dout = w_buf[j];
        m_we = 1;
        #1;
        m_we = 0;
        m_waddr = m_waddr + 1;
    end
    $display("MMU:Write c_waddr:%x len:%d data:%d",c_waddr,c_wlen+1,c_din);
end
endmodule
