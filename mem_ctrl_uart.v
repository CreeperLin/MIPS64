/*mem controller(North Bridge)*/
`include "def.v"
`ifdef SIM
`include "buffer.v"
`endif

module mem_ctrl_uart
(
    input clk, rst,
    input[`M_DATA_L] u_din,
    output reg[`M_DATA_L] u_dout,
    output reg u_re, u_we,
    input u_rack, u_wack,
    input u_ra, u_wa,
    
    input[`C_DATA_L] c_din,
    output[`C_DATA_L] c_dout,
    input[`M_ADDR_L] c_raddr,
    input[`M_ADDR_L] c_waddr,
    input c_re, c_we,
    input[1:0] c_rlen, c_wlen,
    output reg c_rack, c_wack
);
localparam STATE_B          = 6;
localparam STATE_IDLE       = 0;
localparam STATE_R_ADDR     = 1;
localparam STATE_R_DATA     = 2;
localparam STATE_W_ADDR     = 4;
localparam STATE_W_DATA     = 8;
localparam STATE_R_INIT     = 16;
localparam STATE_W_INIT     = 32;
//localparam STATE_R_MASK     = 3;
//localparam STATE_W_MASK     = 6;
reg[STATE_B-1:0] state;

localparam RWBUF_L = 1 + 2 + `K_M_ADDR_L + `K_C_DATA_L;
reg[RWBUF_L-1:0] rwb_din;
wire[RWBUF_L-1:0] rwb_dout;
//wire rwb_rw;
//wire[`RW_LEN_L] rwb_mask;
//wire[`M_ADDR_L] rwb_addr;
//wire[`C_DATA_L] rwb_data;
//assign rwb_addr = rwb_dout[`K_M_ADDR_L+`K_C_DATA_L-1:`K_C_DATA_L];
//assign rwb_rw = rwb_dout[`K_M_ADDR_L+`K_C_DATA_L+2];
//assign rwb_mask = rwb_dout[`K_M_ADDR_L+`K_C_DATA_L+1:`K_M_ADDR_L+`K_C_DATA_L];
//assign rwb_data = rwb_dout[`C_DATA_L];
reg rwb_re, rwb_we;
wire rwb_rack, rwb_wack, rwb_a, rwb_f;
buffer#(.BUF_ID(7),.ADDR_L(5),.DATA_L(RWBUF_L)) rwbuf
(clk,rst,rwb_re,rwb_we,rwb_din,rwb_dout,rwb_rack,rwb_wack,rwb_a,rwb_f);
reg rwb_rw;
reg[`RW_LEN_L] rwb_mask;
reg[`M_ADDR_L] rwb_addr;
reg[`C_DATA_L] rwb_data;

reg[3:0] b_ofs;
reg u_qre, u_qwe;

wire[`M_DATA_L] rwb_data_seg[3:0];
wire[`M_DATA_L] rwb_data_msb;
wire[`M_DATA_L] rwb_addr_seg[3:0];
wire[`M_DATA_L] rwb_addr_msb;
assign rwb_data_msb[7:4] = 4'b0;
assign rwb_addr_msb[7:4] = 4'b0;
genvar i;
generate
    for (i=0;i<4;i=i+1) begin
        assign rwb_data_seg[i] = {1'b0,rwb_data[(i+1)*8-2:i*8]};
        assign rwb_data_msb[i] = rwb_data[(i+1)*8-1];
        assign rwb_addr_seg[i] = {1'b0,rwb_addr[(i+1)*8-2:i*8]};
        assign rwb_addr_msb[i] = rwb_addr[(i+1)*8-1];
    end
endgenerate

reg busy;

reg[`M_DATA_L] c_dout_buf[3:0];
assign c_dout = {c_dout_buf[3],c_dout_buf[2],c_dout_buf[1],c_dout_buf[0]};
task empty_r_buf;
    begin
        c_dout_buf[0] <= 0;
        c_dout_buf[1] <= 0;
        c_dout_buf[2] <= 0;
        c_dout_buf[3] <= 0;
    end
endtask

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= STATE_IDLE;
        busy <= 0;
        rwb_rw <= 0;
        rwb_addr <= 0;
        rwb_mask <= 0;
        rwb_data <= 0;
        b_ofs <= 0;
        u_dout <= 0;
        u_re <= 0;
        u_we <= 0;
        u_qre <= 0;
        u_qwe <= 0;
        c_rack <= 0;
        c_wack <= 0;
        rwb_din <= 0;
        rwb_re <= 0;
        rwb_we <= 0;
    end else begin

    end
end

always @(posedge rwb_wack) begin
    rwb_we <= 0;
end

always @(posedge c_re) begin
    rwb_din <= {1'b1,c_rlen,c_raddr,32'b0};
    $display("MCTRL:C_R_SYN: a:%x b:%b",c_raddr,rwb_din);
    if (rwb_we) begin
        $display("MCTRL:ERROR BUSY");
    end
    rwb_we <= 1;
end

always @(posedge c_we) begin
    rwb_din <= {1'b0,c_wlen,c_waddr,c_din};
    $display("MCTRL:C_W_SYN: a:%x d:%d b:%b",c_waddr,c_din,rwb_din);
    if (rwb_we) begin
        $display("MCTRL:ERROR BUSY");
    end
    rwb_we <= 1;
end

always @(posedge rwb_a) begin
    if (!busy)
        rwb_re <= 1;
end

always @(posedge rwb_rack) begin
    busy <= 1;
    rwb_rw = rwb_dout[`K_M_ADDR_L+`K_C_DATA_L+2];
    rwb_mask = rwb_dout[`K_M_ADDR_L+`K_C_DATA_L+1:`K_M_ADDR_L+`K_C_DATA_L];
    rwb_addr = rwb_dout[`K_M_ADDR_L+`K_C_DATA_L-1:`K_C_DATA_L];
    rwb_data = rwb_dout[`C_DATA_L];
    rwb_re <= 0;
    //$display("MCTRL:RWBUF: %b %b %b %b",rwb_rw,rwb_mask,rwb_addr,rwb_data);
    case (rwb_rw)
        1'b1: begin
            u_dout <= {6'b110000,rwb_mask};
            $display("MCTRL:READ a:%x dout:%x",rwb_addr,u_dout);
            state <= STATE_R_INIT;
            u_qwe <= 1;
        end
        1'b0: begin
            u_dout <= {6'b100000,rwb_mask};
            $display("MCTRL:WRITE a:%x d:%d",rwb_addr,rwb_data);
            state <= STATE_W_INIT;
            u_qwe <= 1;
        end
        default: $display("MCTRL:ERROR unknown rw");
    endcase
end
always @(posedge u_rack) begin
    u_re <= 0;
    case (state)
        STATE_IDLE: begin
            if (rwb_a) begin
                rwb_re <= 1;
            end
        end
        STATE_R_DATA: begin
            c_dout_buf[b_ofs] <= u_din;
            if (b_ofs==rwb_mask) begin
                $display("MCTRL:Read Done %x",c_dout);
                c_rack <= 1;
                b_ofs <= 0;
                busy <= 0;
                state <= STATE_IDLE;
                rwb_re <= rwb_a ? 1 : 0;
            end else begin
                b_ofs <= b_ofs + 1;
                u_qre <= 1;
            end
        end
        default: $display("MCTRL:ERROR unknown rack");
    endcase
end

always @(posedge u_wack) begin
    u_we <= 0;
    case (state)
        STATE_IDLE: begin
            if (rwb_a) begin
                rwb_re <= 1;
            end
        end
        STATE_R_INIT: begin
            b_ofs <= 1;
            u_dout <= rwb_addr_seg[0];
            state <= STATE_R_ADDR;
            u_qwe <= 1; 
        end
        STATE_W_INIT: begin
            b_ofs <= 1;
            u_dout <= rwb_addr_seg[0];
            state <= STATE_W_ADDR;
            u_qwe <= 1;
        end
        STATE_R_ADDR: begin
            case (b_ofs)
            5: begin
                $display("MCTRL:raddr sent %x",rwb_addr);
                b_ofs <= 0;
                c_dout_buf[0] <= 0;
                c_dout_buf[1] <= 0;
                c_dout_buf[2] <= 0;
                c_dout_buf[3] <= 0;
                state <= STATE_R_DATA;
                u_qre <= 1;
            end
            4: begin
                u_dout <= rwb_addr_msb;
                $display("MCTRL:sending raddr msb %b",u_dout);
                b_ofs <= b_ofs + 1;
                u_qwe <= 1;
            end
            1,2,3: begin
                $display("MCTRL:raddr seg %0d sent %b",b_ofs,u_dout);
                u_dout <= rwb_addr_seg[b_ofs];
                b_ofs <= b_ofs + 1;
                u_qwe <= 1;
            end
            endcase
        end
        STATE_W_ADDR: begin
            case (b_ofs)
            5: begin
                $display("MCTRL:waddr sent %x",rwb_addr);
                b_ofs <= 1;
                u_dout <= rwb_data_seg[0];
                state <= STATE_W_DATA;
                u_qwe <= 1;
            end
            4: begin
                u_dout <= rwb_addr_msb;
                b_ofs <= b_ofs + 1;
                u_qwe <= 1;
            end
            1,2,3: begin
                u_dout <= rwb_addr_seg[b_ofs];
                b_ofs <= b_ofs + 1;
                u_qwe <= 1;
            end
            endcase
        end
        STATE_W_DATA: begin
            $display("MCTRL:Write %d %x",b_ofs,u_dout);
            case (b_ofs)
            (rwb_mask+2): begin
                $display("MCTRL:Write done %d",rwb_data);
                b_ofs <= 0;
                c_wack <= 1;
                busy <= 0;
                state <= STATE_IDLE;
                rwb_re <= rwb_a ? 1 : 0;
            end
            (rwb_mask+1): begin
                b_ofs <= b_ofs + 1;
                u_dout <= rwb_data_msb;
                u_qwe <= 1;
            end
            default: begin
                u_dout <= rwb_data_seg[b_ofs];
                b_ofs <= b_ofs + 1;
                u_qwe <= 1;
            end
            endcase
        end
        default: $display("MCTRL:ERROR unknown wack %d",state);
    endcase
end

always @(negedge u_re) begin
    if (u_qre) begin
        if (u_ra) begin
            u_re <= 1;
            u_qre <= 0;
        end
    end
end

always @(negedge u_we) begin
    if (u_qwe) begin
        if (u_wa) begin
            u_we <= 1;
            u_qwe <= 0;
        end
    end
end

always @(posedge u_qre) begin
    if (u_ra && !u_re) begin
        u_re <= 1;
        u_qre <= 0;
    end
end

always @(posedge u_qwe) begin
    if (u_wa && !u_we) begin
        u_we <= 1;
        u_qwe <= 0;
    end
end

always @(posedge u_ra) begin
    if (u_qre) begin
        u_re <= 1;
        u_qre <= 0;
    end
end

always @(posedge u_wa) begin
    if (u_qwe) begin
        u_we <= 1;
        u_qwe <= 0;
    end
end

always @(negedge c_re) begin
    c_rack <= 0;
end

always @(negedge c_we) begin
    c_wack <= 0;
end

endmodule
