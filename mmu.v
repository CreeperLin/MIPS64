/*Memory Management Unit*/
module mmu
#(
    parameter C_DATA_L = 32,
    parameter M_DATA_L = 8,
    parameter MADDR_L = 32,
    parameter C_PORT = 1,
    parameter M_PORT = 1
)
(
    input clk, rst,
    input[M_DATA_L-1:0] m_din,
    output reg[M_DATA_L-1:0] m_dout,
    output reg[MADDR_L-1:0] m_raddr, m_waddr,
    output reg  m_re, m_we,

    input[C_DATA_L-1:0] c_din,
    output reg[C_DATA_L-1:0] c_dout,
    input[MADDR_L-1:0] c_raddr, c_waddr,
    input  c_re, c_we,
    input[1:0] c_rlen, c_wlen
);
reg[M_DATA_L-1:0] r_buf[4*C_PORT-1:0];
reg[M_DATA_L-1:0] w_buf[4*C_PORT-1:0];
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
    end else begin
    end
end
reg[2:0] i,j;
always @(posedge c_re) begin
    empty_r_buf;
    m_raddr = c_raddr;
    for (i=0;i<=c_rlen;i=i+1) begin
        m_re = 1;
        #1;
        r_buf[i] = m_din;
        m_re = 0;
        m_raddr = m_raddr + 1;
    end
    c_dout <= {r_buf[0],r_buf[1],r_buf[2],r_buf[3]};
    $display("MMU:Read m_raddr:%x len:%d data:%x",m_raddr,c_rlen+1,c_dout);
end
always @(posedge c_we) begin
    m_waddr <= c_waddr;
    w_buf[3] <= c_din[31:24];
    w_buf[2] <= c_din[23:16];
    w_buf[1] <= c_din[15:8];
    w_buf[0] <= c_din[7:0];
    for (j=0;j<=c_wlen;j=j+1) begin
        m_dout = w_buf[j];
        m_we = 1;
        m_waddr = m_waddr + 1;
        m_we = 0;
    end
end
endmodule
