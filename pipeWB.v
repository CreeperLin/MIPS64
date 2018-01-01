module pipeWB
(
    input clk, rst,
    input buf_avail,
    output reg buf_re,
    output reg sig_e,
    //input buf_ack,
    
    input wb_e,
    input[31:0] din,
    output reg[31:0] dout,
    input[4:0] idxin,
    output reg[4:0] idxout,
    output reg reg_we
);
always @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_we <= 0;
        buf_re <= 0;
        dout <= 0;
        idxout <= 0;
        //#100;
        sig_e = 1;
        sig_e = #1 0;
    end else begin

    end
end
//assign idxout = idxin;
//assign dout = din;
always @(posedge buf_avail) begin
    buf_re = 1;
    buf_re = #1 0;
    case (wb_e)
        1'b1: begin
            dout = din;
            idxout = idxin;
            reg_we = 1;
            #1;
            reg_we = 0;
            $display("WB: idx:%d val:%d\n",idxout,dout);
        end
        1'b0: begin
            $display("WB:None\n");
        end
        default: $display("WB:ERROR");
    endcase
    sig_e = 1;
    sig_e = #1 0;
end
//always @(negedge buf_avail) begin
    //buf_re <= #1 0;
//end
//always @(posedge buf_ack) begin
    //buf_we <= #1 0;
//end

endmodule
