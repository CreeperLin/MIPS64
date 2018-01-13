`include "def.v"
`ifdef SIM
`include "uart_comm.v"
`endif
module ram_uart(
	input clk,
	input rst,
	output Tx,
	input Rx
);
localparam M_SIZE_B = 21;
localparam M_SIZE = 2**M_SIZE_B;
localparam STATE_B          = 4;
localparam STATE_IDLE       = 0;
localparam STATE_R_ADDR     = 1;
localparam STATE_R_DATA     = 2;
localparam STATE_R_MASK     = 3;
localparam STATE_W_ADDR     = 4;
localparam STATE_W_DATA     = 5;
localparam STATE_W_MASK     = 6;
localparam STATE_R_INIT     = 7;
localparam STATE_W_INIT     = 8;
reg[STATE_B-1:0] state;

reg send_flag;
reg [7:0] send_data;
reg recv_flag;
wire [7:0] recv_data;

wire recvable, sendable, recv_ack, send_ack;
uart_comm #(.ID(3), .BAUDRATE(`BAUD_RATE), .CLOCKRATE(`CLK_RATE)) uart(clk, rst, send_flag, send_data, recv_flag, recv_data, send_ack, recv_ack, sendable, recvable, Tx, Rx);

reg[7:0] memory[M_SIZE-1:0];
//wire[M_DATA_L-1:0] m_din, m_dout;
//wire[MADDR_L-1:0] m_waddr, m_raddr;
//reg m_re, m_we;
//wire m_rack, m_wack;
//ram mem(clk, rst, m_din, m_dout, m_raddr, m_waddr, m_re, m_we, m_rack, m_wack);
//assign m_din = data;
integer fp_r, fp_w, cnt;
integer t;
initial begin
    for(t=0;t<M_SIZE;t=t+1) begin
        memory[t] = 0;
    end
    $readmemh("./test/test.dat", memory);
    fp_r = $fopen("./test/test.in", "r");
    fp_w = $fopen("./test/test.out", "w");
end

//function [`M_ADDR_L] getDWORD;
    //input [`M_ADDR_L] addr;
    //getDWORD = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]};
//endfunction

//function [15:0] getWORD;
    //input [`M_ADDR_L] addr;
    //getWORD = {memory[addr+1], memory[addr]};
//endfunction

//multchan_comm #(.CHANNEL_BIT(1), .MESSAGE_BIT(72)) comm(
    //clk, rst, send_flag, send_data, recv_flag, recv_data, sendable, recvable,
    //{1'b0, read_flag}, {read_data_length, read_data},
    //{1'b0, write_flag}, {write_data_length, write_data},
    //{_trash, readable}, {_trash2, writable});
always @(posedge recvable) begin
    recv_flag = 1;
end

reg[4:0] ofs;
wire[31:0] addr;
wire[31:0] data;
//reg[31:0] data;
wire[7:0] data_byte[3:0];
reg[6:0] addr_seg[3:0];
reg[6:0] data_seg[3:0];
reg[3:0] data_msb;
reg[3:0] addr_msb;
reg[1:0] mask;
genvar i;
generate
    for (i=0;i<4;i=i+1) begin
        assign addr[(i+1)*8-2:i*8] = addr_seg[i];
        assign addr[(i+1)*8-1] = addr_msb[i];
        assign data[(i+1)*8-2:i*8] = data_seg[i];
        assign data[(i+1)*8-1] = data_msb[i];
        assign data_byte[i] = data[(i+1)*8-1:i*8];
    end
endgenerate
reg signed[31:0] outl,inl;
always @(posedge recv_ack) begin
    recv_flag = 0;
    if (recv_data[7]) begin
        if (recv_data[6]) begin
            //$display("RAM:SYN Read");
            ofs = 0;
            state = STATE_R_ADDR;
        end else begin
            //$display("RAM:SYN Write");
            ofs = 0;
            state = STATE_W_ADDR;
        end
    end else begin
        case (state)
            STATE_R_ADDR: begin
                case (ofs)
                    4: begin
                        addr_msb = recv_data[3:0];
                        //$display("RAM:RADDR MSB %b",addr_msb);
                        ofs = 0;
                        state = STATE_R_MASK;
                    end
                    default: begin 
                        addr_seg[ofs] = recv_data[6:0];
                        ofs = ofs + 1;
                    end
                endcase
            end
            STATE_W_ADDR: begin
                case (ofs)
                    4: begin
                        addr_msb = recv_data[3:0];
                        //$display("RAM:WADDR MSB %b",addr_msb);
                        ofs = 0;
                        state = STATE_W_MASK;
                    end
                    default: begin 
                        addr_seg[ofs] = recv_data[6:0];
                        ofs = ofs + 1;
                    end
                endcase
            end
            STATE_R_MASK: begin
                //$display("RAM:RADDR %x",addr);
                mask = recv_data[1:0];
                ofs = 0;
                send_data = memory[addr+ofs];
                case (addr)
                    32'h100: begin
                        memory[addr] = $fgetc(fp_r);
                        $display("IO:InputByte: %c", memory[addr]);
                    end
                endcase
                //$display("RAM:Read Data %x",send_data);
                state = STATE_R_DATA;
                send_flag = 1;
            end
            STATE_W_MASK: begin
                //$display("RAM:WADDR %x",addr);
                mask = recv_data[1:0];
                ofs = 0;
                state = STATE_W_DATA;
            end
            STATE_W_DATA: begin
                case (ofs)
                    (mask+1): begin
                        ofs = 0;
                        data_msb = recv_data[3:0];
                        #1;
                        //data = {data_msb[3],data_seg[3],
                            //data_msb[2],data_seg[2],
                            //data_msb[1],data_seg[1],
                            //data_msb[0],data_seg[0]};
                        //$display("RAM:WDATA MSB %b",data_msb);
                        $display("RAM:WDATA %x",data);
                        case (addr)
                            32'h104: begin
                                $fwrite(fp_w,"%c",data);
                                $display("IO:PrintByte: %c",data);
                                //$write("%c",data);
                            end
                            32'h209: begin
                                outl = {memory[32'h208],memory[32'h207],memory[32'h206],memory[32'h205]};
                                $fwrite(fp_w,"%0d",outl);
                                $display("IO:PrintInt: %0d",outl);
                                //$write("%0d",outl);
                            end
                            32'h200: begin
                                cnt = $fscanf(fp_r,"%d",inl);
                                memory[32'h201] = inl[7:0];
                                memory[32'h202] = inl[15:8];
                                memory[32'h203] = inl[23:16];
                                memory[32'h204] = inl[31:24];
                                $display("IO:InputInt: %d",inl);
                            end
                            32'h108: begin
                                $display("IO:Return %d after %d tck",data,$time);
                                $finish;
                            end
                        endcase
                        for (t=0;t<=mask;t=t+1) begin
                            memory[addr+t] = data_byte[t];
                        end
                    end
                    default: begin 
                        data_seg[ofs] = recv_data[6:0];
                        ofs = ofs + 1;
                    end
                endcase
            end
        endcase
    end
    if (recvable) recv_flag = 1;
end

always @(posedge send_ack) begin
    send_flag = 0;
    case (state)
        STATE_R_DATA: begin
            if (ofs==mask) begin
                ofs = 0;
                state = STATE_IDLE;
            end else begin
                ofs = ofs + 1;
                send_data = memory[addr+ofs];
                //$display("RAM:Read a:%x %x",addr+ofs,send_data);
                send_flag = 1;
            end
        end
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        //data = 0;
        recv_flag = 0;
        send_flag = 0;
        send_data = 0;
        addr_msb = 0;
        state = 0;
        send_data <= 0;
    end else begin
        //if(readable) begin
            //read_flag <= 1;
            //if(read_data_length == 5 && read_data[32] == 0) begin	//read
                //////$display("GET READ REQUEST, ADDR = 0x%x DATA = %x", read_data[`M_ADDR_L], getDWORD(read_data[`M_ADDR_L]));
                //write_flag <= 1;
                //write_data <= getDWORD(read_data[`M_ADDR_L]);
                //write_data_length <= 4;
            //end else begin	//write
                //////$display("GET WRITE REQUEST, ADDR = 0x%x DATA = %x MASK = %d", read_data[63:32], read_data[`M_ADDR_L], read_data[67:64]);
                //if(read_data[64])
                    //memory[read_data[63:32]] <= read_data[7:0];
                //if(read_data[65])
                    //memory[read_data[63:32]+1] <= read_data[15:8];
                //if(read_data[66])
                    //memory[read_data[63:32]+2] <= read_data[23:16];
                //if(read_data[67])
                    //memory[read_data[63:32]+3] <= read_data[31:24];
            //end
        //end
    end
end
endmodule
