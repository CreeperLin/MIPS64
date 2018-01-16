/*IF*/
`include "riscv_const.v"
`define PC_ENTRY 32'h00000000
`define PC_MAIN 32'h00001000
module pipeIF
#(
    parameter INST_L = 32,
    parameter PC_L = 32,
    parameter MADDR_L = 32
)
(
    input clk, rst,
    input sig_e,
    //output reg buf_re,
    output reg buf_we,
    input buf_wack,
    input buf_f,

    //output purge_e,
    input jp_e,
    input[PC_L-1:0] pc_in,
    output reg jp_ack,
    input[INST_L-1:0] datain,
    output [MADDR_L-1:0] addr,
    output reg m_re,
    output [1:0] m_rlen,
    input m_rack,
    output reg[INST_L-1:0] inst,
    output reg[PC_L-1:0] pc,
    output reg[10-1:0] bp_tag_q,
    input bp_t,
    output reg dbg
);

reg sig_s;

reg stall;
reg[PC_L-1:0] nxpc;
assign addr = nxpc[MADDR_L-1:0];

assign m_rlen = 3;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        dbg <= 0;
        pc <= `PC_ENTRY;
        nxpc <= `PC_ENTRY;
        buf_we <= 0;
        inst <= 0;
        m_re <= 0;
        stall <= 0;
        sig_s <= 0;
        jp_ack <= 0;
    end else begin
    end
end

always @(posedge sig_e) begin
    dbg <= 1;
    sig_s <= 1;
end
always @(posedge sig_s) begin
    dbg <= 1;
    if (stall) begin
        $display("IF: stalled");
    end else if (!m_re) begin
        pc <= nxpc;
        m_re <= 1;
    end
    sig_s <= 0;
end

always @(negedge buf_f) begin
    sig_s <= sig_e ? 1 : 0;
end

always @(posedge jp_e) begin
    if (pc_in) begin
        nxpc <= pc_in;
        if (stall) begin
            stall <= 0;
        end else begin
            $display("IF:Purge");
        end
        $display("IF:Goto %x",nxpc);
    end else begin
        stall <= 0;
    end
    sig_s <= buf_f ? 0 : 1;
    jp_ack <= 1;
end

always @(posedge m_rack) begin
    inst = datain;
    m_re <= 0;
    $display("IF: read pc: %x jp_e: %x, inst: %X nxpc: %x",pc,jp_e,inst,nxpc);
    case (inst[6:0])
        `OP_JAL, `OP_JALR: begin
            $display("IF:Jump stall");
            stall <= 1;
        end
        `OP_BRANCH: begin
            bp_tag_q <= nxpc[10-1:0];
            //stall <= bp_t ? 1 : 0;
            stall <= 1;
            $display("IF:Branch stall:%d",stall);
        end
    endcase
    if (inst!=32'b0) begin
        buf_we <= 1;
    end else begin
        $display("NO INSTRUCTION STOP");
        $stop;
    end
    nxpc <= nxpc + 4;
end

always @(posedge buf_wack) begin
    buf_we <= 0;
    sig_s <= (buf_f) ? 0 : 1;
end

always @(negedge jp_e) begin
    jp_ack <= 0;
end
endmodule
