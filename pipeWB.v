module pipeWB
(
    input clk, rst,
    input buf_avail,
    output reg buf_re,
    input buf_rack,
    
    input wb_e,
    input[31:0] din,
    output reg[31:0] dout,
    input[4:0] idxin,
    output reg[4:0] idxout,
    output reg reg_we,
    input reg_wack
);
always @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_we <= 0;
        buf_re <= 0;
        dout <= 0;
        idxout <= 0;
    end else begin

    end
end
always @(posedge buf_avail) begin
    buf_re <= 1;
end

always @(posedge buf_rack) begin
    buf_re <= 0;
    case (wb_e)
        1'b1: begin
            dout <= din;
            idxout <= idxin;
            reg_we <= 1;        
        end
        1'b0: begin
            $display("WB:None\n");
            buf_re <= buf_avail ? 1 : 0;
        end
        default: $display("WB:ERROR");
    endcase
end

always @(posedge reg_wack) begin
    reg_we <= 0;
    buf_re <= buf_avail ? 1 : 0;
    $display("WB: idx:%d val:%d\n",idxout,dout);
end

endmodule
