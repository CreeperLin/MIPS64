/*mem controller(North Bridge)*/
`include "def.v"
`include "buffer.v"

module mem_ctrl_uart
#(
    parameter C_DATA_L = 8,
    parameter M_DATA_L = 8,
    parameter MADDR_L = 32
)
(
    input clk, rst,
    //input[M_DATA_L-1:0] m_din,
    //output[M_DATA_L-1:0] m_dout,
    //output[MADDR_L-1:0] m_raddr,
    //output[MADDR_L-1:0] m_waddr,
    //output m_re,
    //output m_we,
    //input m_rack, m_wack,
    //input Rx,
    //output reg Tx,
    input[`M_DATA_L] u_din,
    output reg[`M_DATA_L] u_dout,
    output reg u_re, u_we,
    input u_rack, u_wack,
    
    input[C_DATA_L-1:0] c_din,
    output[C_DATA_L-1:0] c_dout,
    input[MADDR_L-1:0] c_raddr,
    input[MADDR_L-1:0] c_waddr,
    input c_re, c_we,
    input[1:0] c_rlen, c_wlen,
    output reg c_rack, c_wack
);
localparam STATE_B          = 3;
localparam STATE_IDLE       = 0;
localparam STATE_R_ADDR     = 1;
localparam STATE_R_DATA     = 2;
localparam STATE_R_MASK     = 3;
localparam STATE_W_ADDR     = 4;
localparam STATE_W_DATA     = 5;
localparam STATE_W_MASK     = 6;
reg[STATE_B-1:0] state;

localparam RWBUF_L = 1 + 2 + `K_M_ADDR_L + `K_C_DATA_L;
reg[RBUF_L-1:0] rwb_din;
wire[RBUF_L-1:0] rwb_dout;
wire rwb_rw;
wire[`RW_LEN_L] rwb_mask;
wire[`M_DATA_L] rwb_addr;
wire[`C_DATA_L] rwb_data;
assign rwb_rw = rwb_dout[`K_M_ADDR_L+`K_C_DATA_L+2];
assign rwb_mask = rwb_dout[`K_M_ADDR_L+`K_C_DATA_L+1:`K_M_ADDR_L+`K_C_DATA_L];
assign rwb_addr = rwb_dout[`K_M_ADDR_L+`K_C_DATA_L-1:`K_C_DATA_L];
assign rwb_data = rwb_dout[`C_DATA_L];
reg rwb_re, rwb_we;
wire rwb_rack, rwb_wack, rwb_a, rwb_f;
buffer#(.ID(6),.ADDR_L(5),.DATA_L(RWBUF_L)) rwbuf(
    clk,rst,rwb_re,rwb_we,rwb_din,rwb_dout,rwb_rack,rwb_wack,rwb_a,rwb_f);

reg[3:0] b_ofs;

wire[`M_DATA_L] rwb_data_seg[3:0];
wire[`M_ADDR_L] rwb_addr_buf[3:0];
genvar i;
generate
    for (i=0;i<4;i=i+1) begin
        assign rwb_data_seg[i] = rwb_data[(i+1)*8-1:i*8];
        assign rwb_addr_seg[i] = rwb_addr[(i+1)*8-1:i*8];
    end
endgenerate

reg[`M_DATA_L] c_dout_buf[3:0];
assign c_dout = {c_dout_buf[3],c_dout_buf[2],c_dout_buf[1],c_dout_buf[0]};
task empty_r_buf;
    begin
        c_dout_buf[0] = 0;
        c_dout_buf[1] = 0;
        c_dout_buf[2] = 0;
        c_dout_buf[3] = 0;
    end
endtask

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state = STATE_IDLE;
        b_ofs = 0;
        u_dout = 0;
        u_re = 0;
        u_we = 0;
        //Tx = 0;
        c_rack = 0;
        c_wack = 0;
    end else begin

    end
end

always @(posedge rwb_wack) begin
    rwb_we = 0;
end

always @(posedge c_re) begin
    rwb_din = {1,c_raddr,32'b0};
    $display("MCTRL:C_R_SYN: a:%x b:%b",c_raddr,rwb_din);
    rwb_we = 1;
end

always @(posedge c_we) begin
    rwb_din = {0,c_raddr,c_din};
    $display("MCTRL:C_R_SYN: a:%x d:%d b:%b",c_raddr,c_din,rwb_din);
    rwb_we = 1;
end

always @(posedge rwb_a) begin
    rwb_re = 1;
end

always @(posedge rwb_rack) begin
    rwb_re = 0;
    case (rwb_rw)
        1'b1: begin
            $display("MCTRL:READ a:%x",rwb_addr);
            b_ofs = 0;
            u_dout = rwb_addr_seg[b_ofs];
            u_we = 1; 
        end
        1'b0: begin
            $display("MCTRL:WRITE a:%x d:%d",rwb_addr,rwb_data);
        end
        default: $display("MCTRL:ERROR unknown rw");
    endcase
end

always @(posedge u_rack) begin
    u_re = 0;
    case (state)
        STATE_IDLE: begin
            if (rwb_a) begin
                rwb_re = 1;
            end
        end
        STATE_R_ADDR: begin
            if (b_ofs==3) begin
                $display("MCTRL:raddr sent %x",rwb_addr);
                b_ofs = 0;
                u_dout = {6'b0,c_rlen};
                u_we = 1;
                state = STATE_R_MASK;
            end else begin
                b_ofs = b_ofs + 1;
                u_dout = rwb_addr_seg[b_ofs];
                u_we = 1;
            end
        end
        STATE_R_MASK: begin
            $display("MCTRL:rlen sent %d",rwb_mask);
            b_ofs = 0;
            state = STATE_R_DATA;
            u_re = 1;
        end
        STATE_R_DATA: begin
            c_dout_buf[b_ofs] = u_din;
            b_ofs = b_ofs + 1;
            u_re = 1;
        end
        STATE_W_ADDR: begin
            if (b_ofs==3) begin
                $display("MCTRL:waddr sent %x",rwb_addr);
                b_ofs = 0;
                u_dout = {6'b0,rwb_mask};
                u_we = 1;
                state = STATE_W_MASK;
            end else begin
                b_ofs = b_ofs + 1;
                u_dout = rwb_addr_seg[b_ofs];
                u_we = 1;
            end
        end
        STATE_W_MASK: begin
            $display("MCTRL:wlen sent %d",rwb_mask);
            b_ofs = 0;
            u_dout = rwb_data_seg[b_ofs];
            state = STATE_W_DATA;
            u_we = 1;
        end
        STATE_W_DATA: begin
            if (b_ofs==rwb_mask) begin
                $display("MCTRL:write done %d",rwb_data);
                b_ofs = 0;
                state = STATE_IDLE;
                c_wack = 1;
            end else begin
                b_ofs = b_ofs + 1;
                u_dout = rwb_data_seg[b_ofs];
                u_we = 1;
            end
        end
        default: $display("MCTRL:ERROR unknown rack");
    endcase
end

always @(posedge u_wack) begin
    u_we = 0;
end

always @(negedge c_re) begin
    c_rack = 0;
end

always @(negedge c_we) begin
    c_wack = 0;
end

endmodule
