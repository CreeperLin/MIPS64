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

    //output purge_e,
    input jp_e,
    input[PC_L-1:0] pc_in,
    output reg jp_ack,
    input[INST_L-1:0] datain,
    //output reg[MADDR_L-1:0] addr,
    output [MADDR_L-1:0] addr,
    output reg m_re,
    output [1:0] m_rlen,
    input m_rack,
    output reg[INST_L-1:0] inst,
    //output [PC_L-1:0] nxpc 
    output reg[PC_L-1:0] pc_out,
    output reg[10-1:0] bp_tag_q,
    input bp_t, sig_b
);

reg sig_s;

reg[PC_L-1:0] pc;
reg stall;
reg[PC_L-1:0] nxpc;
//wire[PC_L-1:0] nxpc;
//assign nxpc = (jp_e==1'b1) ? pc_in : pc + 4;
//assign nxpc = pc + 4;

//wire[6:0] inst_op;
//assign inst_op = inst[6:0];
assign addr = nxpc[MADDR_L-1:0];

//task fetch_inst;
//begin
    //re = 1;
    //inst = datain;
    //re = 0;
    ////inst[31:0] = {datain[7:0],datain[15:8],datain[23:16],datain[31:24]};
//end
//endtask

assign m_rlen = 3;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        //pc <= 0;
        pc = `PC_ENTRY;
        nxpc = `PC_ENTRY;
        pc_out = 0;
        //buf_re <= 0;
        buf_we = 0;
        inst = 0;
        //addr = 0;
        m_re = 0;
        stall = 0;
        jp_ack = 0;
        //fetch_inst;
    end else begin
        //if (stall) begin
            //$display("IF: stalled");
        //end else if (!m_re) begin
            //pc = nxpc;
            //pc_out = nxpc;
            ////fetch_inst;
            //m_re = 1;
        //end
    end
end

//always @(posedge sig_e) begin
//always @(sig_e or posedge sig_s) begin
always @(posedge sig_b) begin
    if (stall) begin
        $display("IF: stalled");
    end else if (!m_re) begin
        pc = nxpc;
        pc_out = nxpc;
        //fetch_inst;
        m_re = 1;
    end
end

always @(posedge jp_e) begin
    //j_pc = pc_in;
    if (pc_in) begin
        nxpc = pc_in;
        //fetch_inst;
        if (stall) begin
            stall = 0;
            //sig_s = ~sig_s;
        end else begin
            $display("IF:Purge");
            //purge
        end
        $display("IF:Goto %x",nxpc);
    end else begin
        stall = 0;
        //sig_s = ~sig_s;
    end
    jp_ack = 1;
end

always @(posedge m_rack) begin
    inst = datain;
    //m_re = 0;
    $display("IF: read pc: %x jp_e: %x, inst: %X nxpc: %x",pc,jp_e,inst,nxpc);
    case (inst[6:0])
        `OP_JAL, `OP_JALR: begin
            $display("IF:Jump stall");
            stall = 1;
        end
        `OP_BRANCH: begin
            bp_tag_q = nxpc[10-1:0];
            //stall = bp_t ? 1 : 0;
            stall = 1;
            $display("IF:Branch stall:%d",stall);
        end
        //default: $display("IF:normal inst");
    endcase
    if (inst!=32'b0) begin
        buf_we = 1;
    end else begin
        $display("NO INSTRUCTION STOP");
        $stop;
    end
    nxpc = nxpc + 4;
end

always @(posedge buf_wack) begin
    buf_we = 0;
end

always @(negedge jp_e) begin
    jp_ack = 0;
end
//always @(negedge sig_e) begin
//end

//always @(posedge buf_ack) begin
//end
endmodule
